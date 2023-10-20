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
locals {
  random_id            = random_integer.priority.result
  name                 = "${var.naming_prefix}-default-route-${local.random_id}"
  virtual_service_name = "${var.naming_prefix}-vsvc-${local.random_id}"
  virtual_gateway_name = "${var.naming_prefix}-vgw-${local.random_id}"
  virtual_node_name    = "${var.naming_prefix}-vnode-${local.random_id}"
  namespace_name       = "${local.naming_prefix}.local"
  naming_prefix        = "${var.naming_prefix}${local.random_id}"
  service_name         = "${var.naming_prefix}-svc-${local.random_id}"
  app_mesh_name        = "${var.naming_prefix}-app-mesh-${local.random_id}"
}
