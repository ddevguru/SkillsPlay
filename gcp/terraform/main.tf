locals {
  backend_image  = var.backend_image != "" ? var.backend_image : "us-docker.pkg.dev/cloudrun/container/hello"
  sandbox_image  = var.sandbox_image != "" ? var.sandbox_image : "us-docker.pkg.dev/cloudrun/container/hello"
  cloudsql_conn  = "${var.project_id}:${var.region}:${google_sql_database_instance.main.name}"
  db_url_socket  = "postgresql://${google_sql_user.app.name}:${urlencode(random_password.db_password.result)}@localhost/skillplay?host=/cloudsql/${local.cloudsql_conn}"
  ar_hostname    = "${var.region}-docker.pkg.dev"
  ar_repo_url    = "${local.ar_hostname}/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
