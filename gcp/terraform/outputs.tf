output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "cloud_sql_connection" {
  value = local.cloudsql_conn
}

output "artifact_registry_url" {
  value = local.ar_repo_url
}

output "backend_url" {
  value = google_cloud_run_v2_service.backend.uri
}

output "sandbox_url" {
  value = google_cloud_run_v2_service.sandbox.uri
}

output "database_name" {
  value = google_sql_database.app.name
}

output "database_user" {
  value = google_sql_user.app.name
}

output "backend_image_expected" {
  value = "${local.ar_repo_url}/backend:latest"
}

output "sandbox_image_expected" {
  value = "${local.ar_repo_url}/sandbox:latest"
}

output "seed_job_name" {
  value = google_cloud_run_v2_job.seed.name
}

output "deploy_commands" {
  value = <<-EOT
    # After terraform apply, build & deploy images:
    cd gcp/scripts && ./deploy.sh ${var.project_id} ${var.region}

    # Run database seed (first time only):
    gcloud run jobs execute ${google_cloud_run_v2_job.seed.name} --region=${var.region} --wait
  EOT
}
