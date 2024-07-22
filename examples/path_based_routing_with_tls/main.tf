// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

resource "random_integer" "priority" {
  min = 10000
  max = 50000
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                 = "test-vpc-${local.random_id}"
  cidr                 = var.vpc_cidr
  private_subnets      = var.private_subnets
  azs                  = var.availability_zones
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

module "namespace" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-private_dns_namespace?ref=1.0.0"

  vpc_id = module.vpc.vpc_id
  name   = local.namespace_name
}

module "virtual_node" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-virtual_node?ref=1.0.1"

  acm_certificate_arn        = module.private_cert.certificate_arn
  ports                      = var.ports
  namespace_name             = local.namespace_name
  name                       = local.name
  app_mesh_id                = module.app_mesh.id
  service_name               = local.service_name
  health_check_path          = var.health_check_path
  tls_enforce                = var.tls_enforce
  tls_mode                   = var.tls_mode
  certificate_authority_arns = length(var.certificate_authority_arns) > 0 ? var.certificate_authority_arns : [module.private_ca[0].private_ca_arn]
  health_check_config        = var.health_check_config
  idle_duration              = var.idle_duration
  per_request_timeout        = var.per_request_timeout
  tags                       = var.tags

  depends_on = [module.namespace]
}

module "app_mesh" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-appmesh?ref=1.0.1"

  name = local.app_mesh_name
}

module "appmesh_virtual_service" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-virtual_service?ref=1.0.1"

  name              = local.service_name
  app_mesh_name     = local.app_mesh_name
  virtual_node_name = local.virtual_node_name
  # Not used in this use-case
  virtual_router_name = ""

  tags = var.tags

  depends_on = [module.virtual_node, module.app_mesh]
}

module "appmesh_virtual_gateway" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-virtual_gateway?ref=1.0.1"

  name                                 = local.name
  mesh_name                            = local.app_mesh_name
  tls_enforce                          = var.tls_enforce
  tls_mode                             = var.tls_mode
  tls_ports                            = var.tls_ports
  listener_port                        = var.listener_port
  health_check_port                    = var.listener_port
  acm_certificate_arn                  = module.private_cert.certificate_arn
  trust_acm_certificate_authority_arns = length(var.trust_acm_certificate_authority_arns) > 0 ? var.trust_acm_certificate_authority_arns : [module.private_ca[0].private_ca_arn]

  tags = var.tags

  depends_on = [module.app_mesh]
}

module "appmesh_virtual_gateway_route" {
  source = "../.."

  name                 = local.name
  app_mesh_name        = local.app_mesh_name
  virtual_gateway_name = local.virtual_gateway_name
  virtual_service_name = local.service_name

  # Will match the request for a path `/health` and route it to backend service.
  match_path_prefix = "/health"

  tags = var.tags

  #TODO:
  #The module at module.appmesh_virtual_gateway_route is a legacy module which
  #contains its own local provider configurations, and so calls to it may not
  #use the count, for_each, or depends_on arguments.
  #depends_on = [appmesh_virtual_gateway.listener_port, appmesh_virtual_service.virtual_node_name]
}

module "private_ca" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-private_ca?ref=1.0.1"

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  region                  = var.region
  environment             = var.environment
  environment_number      = var.environment_number
  resource_number         = var.resource_number

  key_algorithm           = var.key_algorithm
  signing_algorithm       = var.signing_algorithm
  subject                 = var.subject
  ca_certificate_validity = var.ca_certificate_validity

  tags = var.tags
}

module "private_cert" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-acm_private_cert?ref=1.0.1"

  # Private CA is created if not passed as input
  private_ca_arn = length(var.certificate_authority_arns) == 0 ? module.private_ca[0].private_ca_arn : var.certificate_authority_arns[0]
  # For virtual gateway
  domain_name = "${local.virtual_gateway_name}.${local.namespace_name}"
  # For virtual Node
  subject_alternative_names = ["${local.virtual_node_name}.${local.namespace_name}"]
}
