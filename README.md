# caylent-gitops-infra
GitOps Infrastructure Repository

Creates basic network infrastructure to host GitOps.
For each environment (dev, qa, prod) this includes:
- VPC
- Private Subnet
- GKE Cluster and Node Pool

The demo makes use of Cloud Build to create the infrastructure, Cloud Storage to hold
Terraform state and Cloud Container Registry to hold application images.

Separate Cloud Build Triggers are defined for base, dev, qa, stage and prod to speed
up build times by building independent environments in parallel.

## Pre-requisites
Before running the bootstrap script, you must have set up several resources in advance.
This demo requires the following:
- A GitHub account where you can fork the associated repositories
- A Google Cloud account and Project
- Bash shell available on the local machine
- Google command-line utilities (gcloud, gsutil) installed on the local machine and available on the path
- Terraform (>0.14.0) installed on the local machine and available on the path
- Git installed on the local machine and available on the path

Detailed instructions are available in a blog article published on https://caylent.com
