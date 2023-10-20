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

resource "aws_appmesh_gateway_route" "this" {
  name                 = var.name
  mesh_name            = var.app_mesh_name
  virtual_gateway_name = var.virtual_gateway_name

  spec {
    http_route {
      action {
        target {
          port = var.virtual_service_port
          virtual_service {
            virtual_service_name = var.virtual_service_name
          }
        }

        rewrite {
          hostname {
            default_target_hostname = var.rewrite_target_hostname
          }
          prefix {
            default_prefix = length(var.rewrite_prefix) > 0 ? null : "ENABLED"
            value          = length(var.rewrite_prefix) > 0 ? var.rewrite_prefix : null
          }
        }
      }

      match {
        # Unable to make the path (exact and regex) to work along side prefix. It complains that prefix cannot be null when the others are set
        # and at the same time doesn't accept both the values set.
        # The prefix should always end with / if the rewrite_prefix is non empty
        prefix = length(var.rewrite_prefix) > 0 && !endswith(var.match_path_prefix, "/") ? "${var.match_path_prefix}/" : var.match_path_prefix

        dynamic "hostname" {
          for_each = coalesce(var.match_hostname_exact, var.match_hostname_suffix, "empty") != "empty" ? [1] : []
          content {
            exact  = var.match_hostname_exact != null ? var.match_hostname_exact : null
            suffix = var.match_hostname_suffix != null ? var.match_hostname_suffix : null
          }
        }
      }
    }
  }

  tags = local.tags
}
