package test

import (
	"context"
	"fmt"
	"os"
	"reflect"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/appmesh"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

var standardTags = map[string]string{
	"provisioner": "Terraform",
}

const (
	base            = "../../examples/"
	testVarFileName = "/test.tfvars"
	caModule        = "module.private_ca"
)

func awsRegion() string {
	for _, v := range []string{os.Getenv("AWS_DEFAULT_REGION"), os.Getenv("AWS_REGION")} {
		if v != "" {
			return v
		}
	}
	return "us-east-2"
}

func appmeshClient(t *testing.T) *appmesh.Client {
	t.Helper()

	loadOpts := []func(*config.LoadOptions) error{
		config.WithRegion(awsRegion()),
	}
	if profile := os.Getenv("AWS_PROFILE"); profile != "" {
		loadOpts = append(loadOpts, config.WithSharedConfigProfile(profile))
	}

	cfg, err := config.LoadDefaultConfig(context.Background(), loadOpts...)
	if err != nil {
		assert.Fail(t, fmt.Sprintf("can't connect to aws: %s", err.Error()))
		return nil
	}

	return appmesh.NewFromConfig(cfg)
}

func TestAppMeshGatewayRouteAndVirtualNode(t *testing.T) {
	t.Parallel()
	stage := test_structure.RunTestStage

	files, err := os.ReadDir(base)
	if err != nil {
		assert.Error(t, err)
	}
	for _, file := range files {
		dir := base + file.Name()
		if file.IsDir() {
			defer stage(t, "teardown_appmesh_virtual_node", func() { tearDownAppMeshVirtualNode(t, dir) })
			defer stage(t, "teardown_appmesh_gateway_route", func() { tearDownAppMeshGatewayRoute(t, dir) })
			stage(t, "setup_and_test_appmesh_virtual_node", func() { setupAndTestAppMeshVirtualNode(t, dir) })
			stage(t, "setup_and_test_appmesh_gateway_route", func() { setupAndTestAppMeshGatewayRoute(t, dir) })
		}
	}
}

func setupAndTestAppMeshGatewayRoute(t *testing.T, dir string) {
	varsFilePath := []string{dir + testVarFileName}

	terraformOptionsCA := &terraform.Options{
		TerraformDir: dir,
		Targets:      []string{caModule},
		VarFiles:     varsFilePath,
		Logger:       logger.Discard,

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	}
	terraformOptionsCA.VarFiles = varsFilePath

	terraformOptions := &terraform.Options{
		TerraformDir: dir,
		VarFiles:     []string{dir + testVarFileName},
		NoColor:      true,
		Logger:       logger.Discard,
	}

	test_structure.SaveTerraformOptions(t, dir, terraformOptions)

	terraform.InitAndApplyContext(t, context.Background(), terraformOptionsCA)
	// sleep for 1 minutes for the CA status change to ISSUED
	// time.Sleep(1 * time.Minute)
	terraform.InitAndApplyContext(t, context.Background(), terraformOptions)

	expectedPatternGatewayARN := "^arn:aws:appmesh:[a-z]{2}-[a-z]+-[0-9]{1}:[0-9]{12}:mesh/[a-zA-Z0-9-]+/virtualGateway/[a-zA-Z0-9-]+$"
	expectedPatternRouteARN := "^arn:aws:appmesh:[a-z]{2}-[a-z]+-[0-9]{1}:[0-9]{12}:mesh/[a-zA-Z0-9-]+/virtualGateway/[a-zA-Z0-9-]+/gatewayRoute/[a-zA-Z0-9-]+$"

	actualVirtualGatewayId := terraform.OutputContext(t, context.Background(), terraformOptions, "vgw_id")
	assert.NotEmpty(t, actualVirtualGatewayId, "Virtual Gateway Id is empty")
	actualGatewayrouteId := terraform.OutputContext(t, context.Background(), terraformOptions, "id")
	assert.NotEmpty(t, actualGatewayrouteId, "Gateway route Id is empty")
	actualVgwARN := terraform.OutputContext(t, context.Background(), terraformOptions, "vgw_arn")
	assert.Regexp(t, expectedPatternGatewayARN, actualVgwARN, "Virtual Gateway ARN does not match expected pattern")
	actualGatewayRouteARN := terraform.OutputContext(t, context.Background(), terraformOptions, "arn")
	assert.Regexp(t, expectedPatternRouteARN, actualGatewayRouteARN, "Gateway route ARN does not match expected pattern")
	actualRandomId := terraform.OutputContext(t, context.Background(), terraformOptions, "random_int")
	assert.NotEmpty(t, actualRandomId, "Random ID is empty")

	logical_product_family     := terraform.GetVariableAsStringFromVarFile(t, dir+testVarFileName, "logical_product_family")
	logical_product_service    := terraform.GetVariableAsStringFromVarFile(t, dir+testVarFileName, "logical_product_service")
	expectedNamePrefix         := logical_product_family + "-" + logical_product_service
	expectedMeshName           := expectedNamePrefix + "-app-mesh-" + actualRandomId
	expectedGatewayRouteName   := expectedNamePrefix + "-vroute-" + actualRandomId
	expectedVirtualGatewayName := expectedNamePrefix + "-vgw-" + actualRandomId

	client := appmeshClient(t)
	if client == nil {
		return
	}
	input := &appmesh.DescribeGatewayRouteInput{
		MeshName:           aws.String(expectedMeshName),
		GatewayRouteName:   aws.String(expectedGatewayRouteName),
		VirtualGatewayName: aws.String(expectedVirtualGatewayName),
	}
	result, err := client.DescribeGatewayRoute(context.Background(), input)
	if err != nil {
		assert.Fail(t, fmt.Sprintf("The Expected Gateway route was not found %s", err.Error()))
		return
	}

	gatewayRoute := result.GatewayRoute
	expectedId := *gatewayRoute.Metadata.Uid
	expectedArn := *gatewayRoute.Metadata.Arn

	assert.Regexp(t, expectedPatternRouteARN, actualGatewayRouteARN, "Gateway route ARN does not match expected pattern")
	assert.Equal(t, expectedArn, actualGatewayRouteARN, "Gateway route ARN does not match")
	assert.Equal(t, expectedId, actualGatewayrouteId, "gateway route id does not match")

	checkTagsMatch(t, dir, actualGatewayRouteARN, client)

}

func setupAndTestAppMeshVirtualNode(t *testing.T, dir string) {
	terraformOptions := &terraform.Options{
		TerraformDir: dir,
		VarFiles:     []string{dir + testVarFileName},
		NoColor:      true,
		Logger:       logger.Discard,
	}

	test_structure.SaveTerraformOptions(t, dir, terraformOptions)

	terraform.InitAndApplyContext(t, context.Background(), terraformOptions)

	expectedPatternNodeARN := "^arn:aws:appmesh:[a-z]{2}-[a-z]+-[0-9]{1}:[0-9]{12}:mesh/[a-zA-Z0-9-]+/virtualNode/[a-zA-Z0-9-]+$"

	actualVirtualNodeARN := terraform.OutputContext(t, context.Background(), terraformOptions, "vnode_arn")
	actualVirtualNodeName := terraform.OutputContext(t, context.Background(), terraformOptions, "vnode_name")
	assert.Regexp(t, expectedPatternNodeARN, actualVirtualNodeARN, "Virtual node ARN does not match expected pattern")
	actualRandomId := terraform.OutputContext(t, context.Background(), terraformOptions, "random_int")
	assert.NotEmpty(t, actualRandomId, "Random ID is empty")

	logical_product_family     := terraform.GetVariableAsStringFromVarFile(t, dir+testVarFileName, "logical_product_family")
	logical_product_service    := terraform.GetVariableAsStringFromVarFile(t, dir+testVarFileName, "logical_product_service")
	expectedNamePrefix := logical_product_family + "-" + logical_product_service
	expectedMeshName   := expectedNamePrefix + "-app-mesh-" + actualRandomId

	client := appmeshClient(t)
	if client == nil {
		return
	}
	input := &appmesh.DescribeVirtualNodeInput{
		MeshName:        aws.String(expectedMeshName),
		VirtualNodeName: aws.String(actualVirtualNodeName),
	}
	result, err := client.DescribeVirtualNode(context.Background(), input)
	if err != nil {
		assert.Fail(t, fmt.Sprintf("The Expected virtual node was not found %s", err.Error()))
		return
	}

	virtualNode  := result.VirtualNode
	expectedName := *virtualNode.VirtualNodeName
	expectedArn  := *virtualNode.Metadata.Arn

	assert.Equal(t, expectedArn, actualVirtualNodeARN, "Virtual node ARN does not match")
	assert.Equal(t, expectedName, actualVirtualNodeName, "Virtual node name does not match")

	checkTagsMatch(t, dir, actualVirtualNodeARN, client)

}

func checkTagsMatch(t *testing.T, dir string, actualARN string, client *appmesh.Client) {
	expectedTags, err := terraform.GetVariableAsMapFromVarFileE(t, dir+testVarFileName, "tags")
	if err == nil {
		result2, errListTags := client.ListTagsForResource(context.Background(), &appmesh.ListTagsForResourceInput{ResourceArn: aws.String(actualARN)})
		if errListTags != nil {
			assert.Error(t, errListTags, "Failed to retrieve tags from AWS")
		}
		// convert AWS Tag[] to map so we can compare
		actualTags := map[string]string{}
		for _, tag := range result2.Tags {
			actualTags[*tag.Key] = *tag.Value
		}

		// add the standard tags to the expected tags
		for k, v := range standardTags {
			expectedTags[k] = v
		}
		expectedTags["env"] = actualTags["env"]
		assert.True(t, reflect.DeepEqual(actualTags, expectedTags), fmt.Sprintf("tags did not match, expected: %v\nactual: %v", expectedTags, actualTags))
	}
}

func tearDownAppMeshGatewayRoute(t *testing.T, dir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, dir)
	terraformOptions.Logger = logger.Discard
	terraform.DestroyContext(t, context.Background(), terraformOptions)

}

func tearDownAppMeshVirtualNode(t *testing.T, dir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, dir)
	terraformOptions.Logger = logger.Discard
	terraform.DestroyContext(t, context.Background(), terraformOptions)
}
