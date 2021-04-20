terraform {
    backend "gcs" {
        bucket = "caylent-gitops-tfstate-p2k7ix"
        prefix = "env"
    }
}