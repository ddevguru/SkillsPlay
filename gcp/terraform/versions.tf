terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Optional: uncomment after creating bucket (see docs/gcp-hosting.md)
  # backend "gcs" {
  #   bucket = "YOUR_PROJECT_ID-tfstate"
  #   prefix = "skillplay"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
