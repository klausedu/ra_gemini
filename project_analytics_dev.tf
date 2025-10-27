# ============================================
# PROJECT: ra-analytics-dev-474600
# ============================================

# --- Habilitar APIs ---
resource "google_project_service" "analytics_apis" {
  provider = google.analytics_dev
  project  = "ra-analytics-dev-474600"
  for_each = toset(["bigquery.googleapis.com", "datacatalog.googleapis.com", "dataproc.googleapis.com", "compute.googleapis.com", "storage.googleapis.com", "appengine.googleapis.com"])
  service  = each.value
  disable_on_destroy = false
}

# --- Espera pelas SAs ---
resource "time_sleep" "wait_for_analytics_sa" {
  create_duration = "90s"
  depends_on      = [google_project_service.analytics_apis]
}

# Criar App Engine para provisionar a Service Account default
resource "google_app_engine_application" "analytics_app" {
  provider     = google.analytics_dev
  project      = "ra-analytics-dev-474600"
  location_id  = "us-central"
  database_type = "CLOUD_FIRESTORE"

  depends_on = [
    google_project_service.analytics_apis["appengine.googleapis.com"]
  ]
}

# --- BigQuery Dataset ---
resource "google_bigquery_dataset" "ra_bq_dev_001" {
  provider      = google.analytics_dev
  dataset_id    = "ra_bq_dev_001"
  friendly_name = "Data Warehouse DEV"
  description   = "Data Warehouse principal (DEV)"
  location      = var.region

  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  default_table_expiration_ms = 7776000000
  
  depends_on = [
    time_sleep.wait_for_analytics_sa,
    google_app_engine_application.analytics_app
  ]
}

# --- Data Catalog Tag Template ---
resource "google_data_catalog_tag_template" "ra_dts_dev_001" {
  provider        = google.analytics_dev
  tag_template_id = "ra_dts_dev_001"
  region          = var.region
  display_name    = "Metadados de Ingestão"
  fields {
    field_id     = "fonte_do_dado"
    display_name = "Fonte do Dado"
    description  = "Sistema ou fonte de origem dos dados"
    type { primitive_type = "STRING" }
    is_required = true
  }
  fields {
    field_id     = "contem_pii"
    display_name = "Contém PII"
    description  = "Indica se contém Informação Pessoal Identificável"
    type { primitive_type = "BOOL" }
    is_required = true
  }
  fields {
    field_id     = "data_ingestao"
    display_name = "Data de Ingestão"
    description  = "Data de ingestão dos dados"
    type { primitive_type = "TIMESTAMP" }
    is_required = false
  }
  fields {
    field_id     = "proprietario"
    display_name = "Proprietário"
    description  = "Equipe ou pessoa responsável pelos dados"
    type { primitive_type = "STRING" }
    is_required = false
  }
  force_delete    = true
  depends_on      = [google_project_service.analytics_apis]
}

# --- Buckets Dataproc ---
resource "google_storage_bucket" "dataproc_staging" {
  provider                    = google.analytics_dev
  name                        = "ra-stg-dataproc-dev-001"
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
  depends_on = [google_project_service.analytics_apis]
}

resource "google_storage_bucket" "dataproc_temp" {
  provider                    = google.analytics_dev
  name                        = "ra-tmp-dataproc-dev-001"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
  depends_on = [google_project_service.analytics_apis]
}

# ==============================================================
# TEMPORARIAMENTE COMENTADO - Problema de permissões Shared VPC
# ==============================================================

/*
# --- Dataproc Cluster ---
resource "google_dataproc_cluster" "dataproc_cluster_dev" {
  provider = google.analytics_dev
  name     = "ra-dataproc-cluster-dev-001"
  region   = var.region

  cluster_config {
    master_config {
      num_instances = 1
      machine_type  = "n2-standard-2"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 50
      }
    }
    worker_config {
      num_instances = 0
    }
    staging_bucket = google_storage_bucket.dataproc_staging.name
    temp_bucket    = google_storage_bucket.dataproc_temp.name
    gce_cluster_config {
      subnetwork = "projects/${google_compute_subnetwork.example_subnet.project}/regions/${google_compute_subnetwork.example_subnet.region}/subnetworks/${google_compute_subnetwork.example_subnet.name}"
      internal_ip_only   = true
      service_account = data.google_compute_default_service_account.dataproc_sa.email
      service_account_scopes = ["cloud-platform"]
      tags            = ["dataproc", "analytics"]
      metadata        = { "enable-oslogin" = "true" }
    }
    software_config {
      image_version       = "2.1-debian11"
      optional_components = ["JUPYTER"]
    }
    endpoint_config {
      enable_http_port_access = false
    }
  }

  depends_on = [
    google_compute_subnetwork_iam_member.dataproc_shared_vpc_user,
    google_storage_bucket.dataproc_staging,
    google_storage_bucket.dataproc_temp,
    time_sleep.wait_for_analytics_sa,
    google_compute_subnetwork.example_subnet
  ]

  labels = {
    environment = "dev"
    managed_by  = "terraform"
    project     = "analytics"
  }
}
*/

# ==============================================================
# FIM DO CÓDIGO COMENTADO - Dataproc
# ==============================================================
