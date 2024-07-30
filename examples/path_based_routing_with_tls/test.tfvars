logical_product_family     = "example"
logical_product_service    = "backend"
tls_mode                   = "STRICT"
listener_port              = "443"
ports                      = [8080]
health_check_path          = "/"
certificate_authority_arns = []
tags = {
  "env" : "gotest",
  "creator" : "terratest",
  "provisioner" : "Terraform",
}
