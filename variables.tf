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

variable "name" {
  description = "Name of the virtual gateway route"
  type        = string
}

variable "app_mesh_name" {
  description = "Id of the App Mesh where the virtual gateway route will reside"
  type        = string
}

variable "virtual_gateway_name" {
  description = "Id of the Virtual Gateway to associated with this gateway route"
  type        = string
}

variable "virtual_service_name" {
  description = "Name of the Virtual Service to set as a target"
  type        = string
}

variable "virtual_service_port" {
  description = "Port of the Virtual service to send traffic to."
  type        = number
  default     = null
}

variable "rewrite_target_hostname" {
  description = "By default, the hostname in the request is rewritten to the hostname of the service. It can be DISABLED"
  type        = string
  default     = "ENABLED"
}

# Match related variables.
variable "match_path_prefix" {
  description = "Gateway route match path prefix. Default is `/`. Conflicts with var.match_path_exact and var.match_path_regex"
  type        = string
  default     = "/"
}

variable "rewrite_prefix" {
  description = <<EOT
    Rewrite the prefix before sending the request to the backend. The supplied prefix will be prepended
    For example if the rewrite_prefix = /test/, then the request /a/b/test.html will be forwarded to the backend
    as /test/a/b/test.html

    EOT
  type        = string
  default     = ""
}

variable "match_hostname_exact" {
  description = "Gateway route match exact hostname. Conflicts with var.match_hostname_suffix"
  type        = string
  default     = null
}

variable "match_hostname_suffix" {
  description = <<EOT
    Gateway route match hostname suffix. Specified ending characters of the host name to match on.
    Conflicts with var.match_hostname_exact
    Example: *.abc.com
  EOT
  type        = string
  default     = null
}

variable "tags" {
  description = "An arbitrary map of tags that can be added to all resources."
  type        = map(string)
  default     = {}
}
