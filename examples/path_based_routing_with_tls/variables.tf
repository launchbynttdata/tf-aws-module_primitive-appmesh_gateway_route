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


variable "logical_product_family" {
  type        = string
  description = <<EOF
    (Required) Name of the product family for which the resource is created.
    Example: org_name, department_name.
  EOF
  nullable    = false
  default     = "launch"

  validation {
    condition     = can(regex("^[_\\-A-Za-z0-9]+$", var.logical_product_family))
    error_message = "The variable must contain letters, numbers, -, _, and .."
  }
}

variable "logical_product_service" {
  type        = string
  description = <<EOF
    (Required) Name of the product service for which the resource is created.
    For example, backend, frontend, middleware etc.
  EOF
  nullable    = false
  default     = "backend"

  validation {
    condition     = can(regex("^[_\\-A-Za-z0-9]+$", var.logical_product_service))
    error_message = "The variable must contain letters, numbers, -, _, and .."
  }
}

variable "environment" {
  description = "Environment in which the resource should be provisioned like dev, qa, prod etc."
  type        = string
  default     = "dev"
}

variable "environment_number" {
  description = "The environment count for the respective environment. Defaults to 000. Increments in value of 1"
  type        = string
  default     = "000"
}

variable "resource_number" {
  description = "The resource count for the respective resource. Defaults to 000. Increments in value of 1"
  type        = string
  default     = "000"
}

variable "region" {
  description = "AWS Region in which the infra needs to be provisioned"
  type        = string
  default     = "us-east-2"
}

## VPC related variables

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet cidrs"
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for the VPC"
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

## Virtual Node

variable "tls_enforce" {
  description = "Whether to enforce TLS on the backends"
  type        = bool
  default     = false
}

variable "tls_mode" {
  description = <<EOF
    Mode of TLS. Default is `STRICT`. Allowed values are DISABLED, STRICT and PERMISSIVE. This is required when
    `tls_enforce=true`
  EOF
  type        = string
  default     = "STRICT"
}

variable "certificate_authority_arns" {
  description = "List of ARNs of private CAs to validate the private certificates"
  type        = list(string)
  default     = []
}

variable "key_algorithm" {
  description = "Type of public key algorithm to use for this CA"
  type        = string
  default     = "RSA_4096"
}

variable "signing_algorithm" {
  description = "Name of the algorithm your private CA uses to sign certificate requests."
  type        = string
  default     = "SHA512WITHRSA"
}

variable "subject" {
  description = "Contains information about the certificate subject. Identifies the entity that owns or controls the public key in the certificate. The entity can be a user, computer, device, or service."
  type = object({
    country                      = optional(string)
    distinguished_name_qualifier = optional(string)
    generation_qualifier         = optional(string)
    given_name                   = optional(string)
    initials                     = optional(string)
    locality                     = optional(string)
    organization                 = optional(string)
    organizational_unit          = optional(string)
    state                        = optional(string)
  })
  default = {
    country             = "US"
    organization        = "Launch by NTT DATA"
    state               = "Texas"
    organizational_unit = "DSO"
  }
}

variable "ca_certificate_validity" {
  description = "Configures end of the validity period for the CA ROOT certificate. Defaults to 1 year"
  type = object({
    type  = string
    value = number
  })

  default = {
    type  = "YEARS"
    value = 10
  }
}

variable "health_check_config" {
  type = object({
    healthy_threshold   = number
    interval_millis     = number
    timeout_millis      = number
    unhealthy_threshold = number
  })

  default = {
    healthy_threshold   = 2
    interval_millis     = 50000
    timeout_millis      = 50000
    unhealthy_threshold = 3
  }
}

variable "health_check_path" {
  description = "Destination path for the health check request"
  type        = string
  default     = ""
}

variable "idle_duration" {
  description = "Idle duration for all the listeners"
  type = object({
    unit  = string
    value = number
  })
  default = null
}

variable "per_request_timeout" {
  description = "Per Request timeout for all the listeners"
  type = object({
    unit  = string
    value = number
  })
  default = null
}

## Service Discovery

## DNS (conflicts with Service Discovery)
variable "ports" {
  description = "Application port"
  type        = list(number)
}


## Virtual Gateway
variable "tls_ports" {
  description = "If you specify a listener port other than 443, you must specify this field."
  type        = list(number)
  default     = []
}

variable "listener_port" {
  description = "The port mapping information for the listener."
  type        = number
  default     = 8080
}

variable "trust_acm_certificate_authority_arns" {
  description = "One or more Amazon Resource Names (ARNs)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "An arbitrary map of tags that can be added to all resources."
  type        = map(string)
  default     = {}
}
