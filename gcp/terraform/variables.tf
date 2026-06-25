variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region (e.g. asia-south1 for Mumbai)"
  type        = string
  default     = "asia-south1"
}

variable "app_name" {
  description = "Application name prefix for resources"
  type        = string
  default     = "skillplay"
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "cors_origin" {
  description = "Comma-separated CORS origins for API"
  type        = string
  default     = "*"
}

variable "backend_image" {
  description = "Backend container image URL (set after first build)"
  type        = string
  default     = ""
}

variable "sandbox_image" {
  description = "Sandbox container image URL (set after first build)"
  type        = string
  default     = ""
}

variable "backend_min_instances" {
  type    = number
  default = 0
}

variable "backend_max_instances" {
  type    = number
  default = 5
}
