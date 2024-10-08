variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "backups_enabled" {
  type    = bool
  default = true
}

variable "deny_unsecured_traffic" {
  type    = bool
  default = true
}

variable "read_replica_enabled" {
  type        = bool
  description = "Create an EFS read replica"
  default     = false
}

variable "extra_fs_policy_documents_json" {
  type        = list(string)
  # Really only used for datasync, which for some reason
  # doesn't accept IAM role-based (and so have to set resource-based via file system policy)
  description = "Extra file system policy documents. Input the 'json' attribute from data.aws_iam_policy_document"
  default     = []
}

variable "efs_name_prefix" {
  # Should begin with '-' if present (i.e. "-sftp")
  type    = string
  default = ""
}

variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}

variable "networking_module" {
  type = object({
    vpc_id                     = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
  })
}
