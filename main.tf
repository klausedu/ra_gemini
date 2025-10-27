terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

# Provedor para o projeto 'ra-data-pipeline-dev'
provider "google" {
  alias   = "data_pipeline"
  project = "ra-data-pipeline-dev"
  region  = var.region
}

# Provedor para o projeto 'ra-infra-shared-services-dev'
provider "google" {
  alias   = "infra_shared"
  project = "ra-infra-shared-services-dev"
  region  = var.region
}

# Provedor para o projeto 'ra-analytics-dev'
provider "google" {
  alias                 = "analytics_dev"
  project               = "ra-analytics-dev-474600"
  region                = var.region
  user_project_override = true
  billing_project       = "ra-analytics-dev-474600"
}

# Provedor alternativo para Analytics (mesmo projeto, alias diferente)
provider "google" {
  alias                 = "analytics"
  project               = "ra-analytics-dev-474600"
  region                = var.region
  user_project_override = true
  billing_project       = "ra-analytics-dev-474600"
}