resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

resource "random_password" "jwt_refresh_secret" {
  length  = 48
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "${var.app_name}-pg"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }

  deletion_protection = false

  depends_on = [google_project_service.apis]
}

resource "google_sql_database" "app" {
  name     = "skillplay"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = "skillplay"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}
