resource "google_cloud_run_v2_service" "sandbox" {
  name     = "${var.app_name}-sandbox"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.sandbox.email

    containers {
      image = local.sandbox_image
      ports {
        container_port = 4001
      }
      env {
        name  = "PORT"
        value = "4001"
      }
      env {
        name  = "MEMORY_LIMIT_MB"
        value = "128"
      }
      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }
    }

    scaling {
      max_instance_count = 3
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service" "backend" {
  name     = "${var.app_name}-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.backend.email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [local.cloudsql_conn]
      }
    }

    containers {
      image = local.backend_image
      ports {
        container_port = 3000
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "PORT"
        value = "3000"
      }
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt_secret.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_REFRESH_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt_refresh_secret.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "SANDBOX_URL"
        value = google_cloud_run_v2_service.sandbox.uri
      }
      env {
        name  = "SANDBOX_USE_IDENTITY"
        value = "true"
      }
      env {
        name  = "MOCK_PAYMENTS"
        value = "true"
      }
      env {
        name  = "FREE_PLAYS_PER_TOPIC"
        value = "10"
      }
      env {
        name  = "CORS_ORIGIN"
        value = var.cors_origin
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 3000
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 6
      }
    }

    scaling {
      min_instance_count = var.backend_min_instances
      max_instance_count = var.backend_max_instances
    }
  }

  depends_on = [
    google_project_service.apis,
    google_cloud_run_v2_service.sandbox,
    google_secret_manager_secret_version.database_url,
  ]
}

resource "google_cloud_run_v2_job" "seed" {
  name     = "${var.app_name}-seed"
  location = var.region

  template {
    template {
      service_account = google_service_account.backend.email

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [local.cloudsql_conn]
        }
      }

      containers {
        image   = local.backend_image
        command = ["sh", "-c", "npx prisma migrate deploy && npm run db:seed"]

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }

        env {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.database_url.secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }

  depends_on = [google_cloud_run_v2_service.backend]
}
