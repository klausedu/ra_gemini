# ============================================
# OUTPUTS - Informações úteis após o deploy
# ============================================

# --- Projeto Infra Shared ---
output "shared_vpc_network_id" {
  description = "ID da Shared VPC Network (criada pelo Terraform)"
  value       = google_compute_network.ra_vpc_dev_001.id
}
output "shared_vpc_network_name" {
  description = "Nome da Shared VPC Network (criada pelo Terraform)"
  value       = google_compute_network.ra_vpc_dev_001.name
}
output "shared_vpc_subnet_id" {
  description = "ID da Subnet principal da Shared VPC (criada pelo Terraform)"
  value       = google_compute_subnetwork.example_subnet.id
}
output "shared_vpc_subnet_cidr" {
  description = "CIDR da Subnet principal"
  value       = google_compute_subnetwork.example_subnet.ip_cidr_range
}
output "nat_external_ip" {
  description = "IP externo do Cloud NAT"
  value       = google_compute_address.ra_ip_dev_001.address
}
output "secret_manager_secret_id" {
  description = "ID do Secret Manager"
  value       = google_secret_manager_secret.ra_key_dev_001.secret_id
}
output "logging_bucket_name" {
  description = "Nome do bucket de logs"
  value       = google_storage_bucket.logging_bucket.name
}
output "monitoring_uptime_check_id" {
  description = "ID do Uptime Check"
  value       = google_monitoring_uptime_check_config.ra_mon_dev_001.uptime_check_id
}

# --- Projeto Data Pipeline ---
output "cloud_function_1_url" {
  description = "URL da Cloud Function 1"
  value       = google_cloudfunctions2_function.ra_fnc_dev_001.service_config[0].uri
}
output "cloud_function_2_url" {
  description = "URL da Cloud Function 2"
  value       = google_cloudfunctions2_function.ra_fnc_dev_002.service_config[0].uri
}

output "functions_staging_bucket" {
  description = "Bucket de staging das Functions"
  value       = google_storage_bucket.functions_staging.name
}
output "data_storage_bucket" {
  description = "Bucket de dados (ra-sa-dev-001)"
  value       = google_storage_bucket.ra_sa_dev_001.name
}

# --- Projeto Analytics ---
output "bigquery_dataset_id" {
  description = "ID do dataset BigQuery"
  value       = google_bigquery_dataset.ra_bq_dev_001.dataset_id
}
output "bigquery_dataset_location" {
  description = "Localização do dataset BigQuery"
  value       = google_bigquery_dataset.ra_bq_dev_001.location
}
output "data_catalog_tag_template_id" {
  description = "ID do Data Catalog Tag Template"
  value       = google_data_catalog_tag_template.ra_dts_dev_001.id
}
output "dataproc_staging_bucket" {
  description = "Bucket de staging do Dataproc"
  value       = google_storage_bucket.dataproc_staging.name
}

# --- Service Accounts ---
output "dataproc_service_account" {
  description = "Email da Service Account do Dataproc"
  value       = data.google_compute_default_service_account.dataproc_sa.email
}

# --- Resumo da Arquitetura ---
output "architecture_summary" {
  description = "Resumo da arquitetura implantada"
  value = {
    organization      = var.organization_id
    region            = var.region
    host_project      = "ra-infra-shared-services-dev"
    shared_vpc_status = "Host Project e anexos gerenciados manualmente pelo Admin da Organização"
    service_projects  = ["ra-data-pipeline-dev", "ra-analytics-dev-474600"]
    shared_vpc_tf = {
      network = google_compute_network.ra_vpc_dev_001.name
      subnet  = google_compute_subnetwork.example_subnet.name
      cidr    = google_compute_subnetwork.example_subnet.ip_cidr_range
    }
    data_pipeline = {
      functions      = [google_cloudfunctions2_function.ra_fnc_dev_001.name, google_cloudfunctions2_function.ra_fnc_dev_002.name]
      storage_bucket = google_storage_bucket.ra_sa_dev_001.name
    }
    analytics = {
      bigquery_dataset     = google_bigquery_dataset.ra_bq_dev_001.dataset_id
      datacatalog_template = google_data_catalog_tag_template.ra_dts_dev_001.tag_template_id
    }
  }
}
