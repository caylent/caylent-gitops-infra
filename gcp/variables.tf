variable "project" {
  type = string
  description = "Name of the GCP project which holds created resources"
}

variable "tf_state_bucket" {
  type = string
  description = "Name of the bucket in GCP which holds the terraform state"
}

variable "github_owner" {
  type = string
  description = "GitHub account owning the repositories"
}

variable "github_app_repo" {
  type = string
  description = "GitHub repository containing application code"
}

variable "github_infra_repo" {
  type = string
  description = "GitHub repository containing infrastructure definitions"
}
