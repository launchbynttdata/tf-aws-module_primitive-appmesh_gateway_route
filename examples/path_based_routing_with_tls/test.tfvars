naming_prefix              = "example"
tls_mode                   = "STRICT"
listener_port              = "443"
port                       = 8080
health_check_path          = "/"
certificate_authority_arns = []
tags = {
  "env" : "gotest",
  "creator" : "terratest",
  "provisioner" : "Terraform",
}
