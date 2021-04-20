terraform {
    required_version = ">= 0.13.0"

    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = ">= 1.13.0"
        }
    }

    backend "gcs" {
        bucket = "caylent-gitops-tfstate-p2k7ix"
        prefix = "env/dev"
    }
}