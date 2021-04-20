variable "env" {
  type = string
}

variable "company" {
  type = string
}

variable "project" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}

variable "region_name" {
  type = string
}

variable "private_subnet" {
  type = string
}

variable "gke_username" {
  type = string
}

variable "gke_password" {
  type = string
}

variable "gke_num_nodes" {
  type = number
}

variable "argo_cd_version" {
  type = string
}

variable "argo_cd_namespace" {
  type = string
}

variable "argo_cd_ha" {
  type = bool
}