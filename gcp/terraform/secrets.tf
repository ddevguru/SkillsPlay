resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.app_name}-db-password"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "${var.app_name}-jwt-secret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

resource "google_secret_manager_secret" "jwt_refresh_secret" {
  secret_id = "${var.app_name}-jwt-refresh-secret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "jwt_refresh_secret" {
  secret      = google_secret_manager_secret.jwt_refresh_secret.id
  secret_data = random_password.jwt_refresh_secret.result
}

resource "google_secret_manager_secret" "database_url" {
  secret_id = "${var.app_name}-database-url"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = local.db_url_socket
}
