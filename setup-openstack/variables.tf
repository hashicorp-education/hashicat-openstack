# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "instance_type" {
  # default     = "m7i-flex.2xlarge"
  default     = "t3.xlarge" # Instruqt allowed largest instance.
  description = "Instance type to use for the instance."
}