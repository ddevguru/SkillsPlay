resource "google_service_account" "backend" {
  account_id   = "${var.app_name}-api"
  display_name = "SkillPlay Backend Cloud Run"
}

resource "google_service_account" "sandbox" {
  account_id   = "${var.app_name}-sandbox"
  display_name = "SkillPlay Sandbox Cloud Run"
}

resource "google_project_iam_member" "backend_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_project_iam_member" "backend_secret" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_cloud_run_v2_service_iam_member" "backend_invokes_sandbox" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.sandbox.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_cloud_run_v2_service_iam_member" "api_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
