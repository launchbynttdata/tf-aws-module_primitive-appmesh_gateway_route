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

output "id" {
  description = "ID of the gateway route"
  value       = module.appmesh_virtual_gateway_route.id
}

output "arn" {
  description = "ARN of the gateway route"
  value       = module.appmesh_virtual_gateway_route.arn
}

output "vgw_id" {
  description = "ID of the virtual gateway"
  value       = module.appmesh_virtual_gateway.id
}

output "vgw_arn" {
  description = "ARN of the virtual gateway"
  value       = module.appmesh_virtual_gateway.arn
}

output "random_int" {
  description = "Random Int postfix"
  value       = random_integer.priority.result
}
