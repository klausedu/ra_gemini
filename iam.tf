# ============================================
# IAM - Identity and Access Management
# ============================================

# --- Data Sources ---
data "google_project" "data_pipeline" {
  provider   = google.data_pipeline
  project_id = "ra-data-pipeline-dev"
}

data "google_project" "analytics" {
  provider   = google.analytics_dev
  project_id = "ra-analytics-dev-474600"
}

data "google_compute_default_service_account" "dataproc_sa" {
  provider = google.analytics_dev
  project  = "ra-analytics-dev-474600"
  depends_on = [google_project_service.analytics_apis]
}

# --- Permissões para Shared VPC ---

resource "google_compute_subnetwork_iam_member" "dataproc_shared_vpc_user" {
  provider   = google.infra_shared
  project    = google_compute_subnetwork.example_subnet.project
  region     = google_compute_subnetwork.example_subnet.region
  subnetwork = google_compute_subnetwork.example_subnet.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_compute_default_service_account.dataproc_sa.email}"
  
  depends_on = [
    google_compute_subnetwork.example_subnet,
    google_app_engine_application.analytics_app,
    time_sleep.wait_for_analytics_sa
  ]
}

resource "google_compute_subnetwork_iam_member" "functions_shared_vpc_user" {
  provider   = google.infra_shared
  project    = google_compute_subnetwork.example_subnet.project
  region     = google_compute_subnetwork.example_subnet.region
  subnetwork = google_compute_subnetwork.example_subnet.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.data_pipeline.number}@gcf-admin-robot.iam.gserviceaccount.com"
  
  depends_on = [
    google_compute_subnetwork.example_subnet,
    google_app_engine_application.pipeline_app,
    time_sleep.wait_for_data_pipeline_sa
  ]
}

# COMENTADO - Service Account BigQuery é criada automaticamente ao usar BigQuery
# Descomentar depois de fazer a primeira query no BigQuery
/*
resource "google_compute_subnetwork_iam_member" "bigquery_shared_vpc_user" {
  provider   = google.infra_shared
  project    = google_compute_subnetwork.example_subnet.project
  region     = google_compute_subnetwork.example_subnet.region
  subnetwork = google_compute_subnetwork.example_subnet.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.analytics.number}@gcp-sa-bigquery.iam.gserviceaccount.com"
  
  depends_on = [
    google_bigquery_dataset.ra_bq_dev_001,
    google_compute_subnetwork.example_subnet
  ]
}
*/

# --- Permissões do Dataproc ---
resource "google_project_iam_member" "dataproc_bigquery_admin" {
  provider   = google.analytics_dev
  project    = "ra-analytics-dev-474600"
  role       = "roles/bigquery.admin"
  member     = "serviceAccount:${data.google_compute_default_service_account.dataproc_sa.email}"
  
  depends_on = [
    google_app_engine_application.analytics_app,
    time_sleep.wait_for_analytics_sa
  ]
}

resource "google_project_iam_member" "dataproc_storage_admin" {
  provider   = google.analytics_dev
  project    = "ra-analytics-dev-474600"
  role       = "roles/storage.admin"
  member     = "serviceAccount:${data.google_compute_default_service_account.dataproc_sa.email}"
  
  depends_on = [
    google_app_engine_application.analytics_app,
    time_sleep.wait_for_analytics_sa
  ]
}

resource "google_project_iam_member" "dataproc_datacatalog_admin" {
  provider   = google.analytics_dev
  project    = "ra-analytics-dev-474600"
  role       = "roles/datacatalog.admin"
  member     = "serviceAccount:${data.google_compute_default_service_account.dataproc_sa.email}"
  
  depends_on = [
    google_app_engine_application.analytics_app,
    time_sleep.wait_for_analytics_sa
  ]
}

# --- Permissões das Cloud Functions ---
resource "google_project_iam_member" "functions_bigquery_jobuser" {
  provider   = google.analytics_dev
  project    = "ra-analytics-dev-474600"
  role       = "roles/bigquery.jobUser"
  member     = "serviceAccount:ra-data-pipeline-dev@appspot.gserviceaccount.com"
  
  depends_on = [
    google_app_engine_application.pipeline_app,
    time_sleep.wait_for_data_pipeline_sa
  ]
}

resource "google_project_iam_member" "functions_bigquery_dataeditor" {
  provider   = google.analytics_dev
  project    = "ra-analytics-dev-474600"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:ra-data-pipeline-dev@appspot.gserviceaccount.com"
  
  depends_on = [
    google_app_engine_application.pipeline_app,
    time_sleep.wait_for_data_pipeline_sa
  ]
}

resource "google_storage_bucket_iam_member" "functions_storage_access" {
  provider   = google.data_pipeline
  bucket     = google_storage_bucket.ra_sa_dev_001.name
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:ra-data-pipeline-dev@appspot.gserviceaccount.com"
  
  depends_on = [
    google_app_engine_application.pipeline_app,
    time_sleep.wait_for_data_pipeline_sa
  ]
}

resource "google_secret_manager_secret_iam_member" "functions_secret_accessor" {
  provider   = google.infra_shared
  project    = "ra-infra-shared-services-dev"
  secret_id  = google_secret_manager_secret.ra_key_dev_001.secret_id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:ra-data-pipeline-dev@appspot.gserviceaccount.com"
  
  depends_on = [
    google_app_engine_application.pipeline_app,
    time_sleep.wait_for_data_pipeline_sa,
    google_secret_manager_secret.ra_key_dev_001
  ]
}

# --- Logging Writer Permissions ---
resource "google_project_iam_member" "log_writer" {
  provider   = google.infra_shared
  project    = "ra-infra-shared-services-dev"
  role       = "roles/logging.logWriter"
  member     = google_logging_project_sink.ra_log_dev_001.writer_identity
  depends_on = [google_logging_project_sink.ra_log_dev_001]
}
