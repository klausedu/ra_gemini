# ============================================
# PROJECT: ra-data-pipeline-dev
# ============================================

# --- Habilitar APIs ---
resource "google_project_service" "data_pipeline_apis" {
  provider = google.data_pipeline
  project  = "ra-data-pipeline-dev"
  for_each = toset(["cloudfunctions.googleapis.com", "cloudbuild.googleapis.com", "storage.googleapis.com", "compute.googleapis.com", "run.googleapis.com", "artifactregistry.googleapis.com", "vpcaccess.googleapis.com", "appengine.googleapis.com"])
  service  = each.value
  disable_on_destroy = false
}

# --- Espera pelas SAs ---
resource "time_sleep" "wait_for_data_pipeline_sa" {
  create_duration = "90s"
  depends_on      = [google_project_service.data_pipeline_apis]
}

# Criar App Engine para provisionar a Service Account default
resource "google_app_engine_application" "pipeline_app" {
  provider     = google.data_pipeline
  project      = "ra-data-pipeline-dev"
  location_id  = var.region
  database_type = "CLOUD_FIRESTORE" # Ou "CLOUD_DATASTORE_COMPATIBILITY"

  depends_on = [
    google_project_service.data_pipeline_apis["appengine.googleapis.com"]
  ]
}

# --- Conector VPC ---
resource "google_vpc_access_connector" "connector" {
  provider      = google.data_pipeline
  name          = "ra-vpc-connector-dev"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  # Referência explícita à rede no projeto Host
  network       = "projects/${google_compute_network.ra_vpc_dev_001.project}/global/networks/${google_compute_network.ra_vpc_dev_001.name}"

  depends_on = [
    google_project_service.data_pipeline_apis["vpcaccess.googleapis.com"],
    google_compute_network.ra_vpc_dev_001 # Garante que a rede exista
  ]
}

# --- Data Source, Buckets, Object ---
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/functions" # Certifique-se que esta pasta existe
  output_path = "/tmp/function-source.zip"
}
resource "google_storage_bucket" "functions_staging" {
  provider                    = google.data_pipeline
  name                        = "ra-stg-functions-dev-001"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
  depends_on = [google_project_service.data_pipeline_apis]
}
resource "google_storage_bucket_object" "function_zip" {
  provider   = google.data_pipeline
  name       = "source-code/function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket     = google_storage_bucket.functions_staging.name
  source     = data.archive_file.function_source.output_path
  depends_on = [data.archive_file.function_source, google_storage_bucket.functions_staging]
}
resource "google_storage_bucket" "ra_sa_dev_001" {
  provider                    = google.data_pipeline
  name                        = "ra-sa-dev-001"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      age                = 30
      num_newer_versions = 3
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
  depends_on = [google_project_service.data_pipeline_apis]
}

# --- Cloud Functions ---
resource "google_cloudfunctions2_function" "ra_fnc_dev_001" {
  provider = google.data_pipeline
  name     = "ra-fnc-dev-001"
  location = var.region
  build_config {
    runtime     = "python311"
    entry_point = "hello_world" # Certifique-se que existe uma função 'hello_world' no seu código
    source {
      storage_source {
        bucket = google_storage_bucket.functions_staging.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }
  service_config {
    available_memory   = "256M"
    timeout_seconds    = 60
    max_instance_count = 10
    all_traffic_on_latest_revision = true
    ingress_settings   = "ALLOW_INTERNAL_ONLY"
    vpc_connector      = google_vpc_access_connector.connector.id
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
    environment_variables = {
      ENVIRONMENT = "dev"
      PROJECT_ID  = "ra-data-pipeline-dev"
    }
  }
  depends_on = [google_storage_bucket_object.function_zip, google_vpc_access_connector.connector]
}
resource "google_cloudfunctions2_function" "ra_fnc_dev_002" {
  provider = google.data_pipeline
  name     = "ra-fnc-dev-002"
  location = var.region
  build_config {
    runtime     = "python311"
    entry_point = "hello_world" # Certifique-se que existe uma função 'hello_world' no seu código
    source {
      storage_source {
        bucket = google_storage_bucket.functions_staging.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }
  service_config {
    available_memory   = "256M"
    timeout_seconds    = 60
    max_instance_count = 10
    all_traffic_on_latest_revision = true
    ingress_settings   = "ALLOW_INTERNAL_ONLY"
    vpc_connector      = google_vpc_access_connector.connector.id
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
    environment_variables = {
      ENVIRONMENT = "dev"
      PROJECT_ID  = "ra-data-pipeline-dev"
    }
  }
  depends_on = [google_storage_bucket_object.function_zip, google_vpc_access_connector.connector]
}

# --- Permissões das Functions ---
resource "google_cloudfunctions2_function_iam_member" "fnc_001_invoker" {
  provider       = google.data_pipeline
  project        = google_cloudfunctions2_function.ra_fnc_dev_001.project
  location       = google_cloudfunctions2_function.ra_fnc_dev_001.location
  cloud_function = google_cloudfunctions2_function.ra_fnc_dev_001.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:ra-data-pipeline-dev@appspot.gserviceaccount.com"
  depends_on     = [time_sleep.wait_for_data_pipeline_sa, google_cloudfunctions2_function.ra_fnc_dev_001]
}
resource "google_cloudfunctions2_function_iam_member" "fnc_002_invoker" {
  provider       = google.data_pipeline
  project        = google_cloudfunctions2_function.ra_fnc_dev_002.project
  location       = google_cloudfunctions2_function.ra_fnc_dev_002.location
  cloud_function = google_cloudfunctions2_function.ra_fnc_dev_002.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:ra-data-pipeline-dev@appspot.gserviceaccount.com"
  depends_on     = [time_sleep.wait_for_data_pipeline_sa, google_cloudfunctions2_function.ra_fnc_dev_002]
}