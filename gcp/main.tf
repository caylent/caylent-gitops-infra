provider "google" {
    project = var.project
}

resource "google_project_service" "enable-cloud-resource-manager" {
    project = var.project
    service = "cloudresourcemanager.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-service-usage" {
    project = var.project
    service = "serviceusage.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-iam" {
    project = var.project
    service = "iam.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-cloud-storage" {
    project = var.project
    service = "storage.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-cloud-storage-api" {
    project = var.project
    service = "storage-api.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-cloud-storage-component" {
    project = var.project
    service = "storage-component.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-cloud-build" {
    project = var.project
    service = "cloudbuild.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-container-registry" {
    project = var.project
    service = "containerregistry.googleapis.com"

    disable_dependent_services = true
}

resource "google_project_service" "enable-container-engine" {
    project = var.project
    service = "container.googleapis.com"

    disable_dependent_services = true
}


# Create Build Trigger for the infrastructure BASE
resource "google_cloudbuild_trigger" "infra-base-build-trigger" {
    name = "infra-base-build-trigger"
    description = "Triggers an update of the infrastructure when a new tag is pushed."
    github {
        owner   = var.github_owner
        name    = var.github_infra_repo
        push {
            tag = "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"
        }
    }

    filename = "gcp/cloudbuild.yaml"
}

# Create Build Trigger for the infrastructure DEV
resource "google_cloudbuild_trigger" "infra-dev-build-trigger" {
    name = "infra-dev-build-trigger"
    description = "Triggers an update of the DEV infrastructure when a new tag is pushed."
    github {
        owner   = var.github_owner
        name    = var.github_infra_repo
        push {
            tag = "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"
        }
    }

    filename = "gcp/environments/dev/cloudbuild.yaml"
}

# Create Build Trigger for the infrastructure QA
resource "google_cloudbuild_trigger" "infra-qa-build-trigger" {
    name = "infra-qa-build-trigger"
    description = "Triggers an update of the QA infrastructure when a new tag is pushed."
    github {
        owner   = var.github_owner
        name    = var.github_infra_repo
        push {
            tag = "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"
        }
    }

    filename = "gcp/environments/qa/cloudbuild.yaml"
}

# Create Build Trigger for the infrastructure PROD
resource "google_cloudbuild_trigger" "infra-prod-build-trigger" {
    name = "infra-prod-build-trigger"
    description = "Triggers an update of the PROD infrastructure when a new tag is pushed."
    github {
        owner   = var.github_owner
        name    = var.github_infra_repo
        push {
            tag = "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"
        }
    }

    filename = "gcp/environments/prod/cloudbuild.yaml"
}

# Create Build Trigger for the application
resource "google_cloudbuild_trigger" "app-build-trigger" {
    name = "app-build-trigger"
    description = "Triggers a fresh build of the application when a new tag is pushed."
    github {
        owner   = var.github_owner
        name    = var.github_app_repo
        push {
            tag = "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"
        }
    }

    filename = "cloudbuild.yaml"
}