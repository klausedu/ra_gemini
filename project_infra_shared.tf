# ============================================
# PROJECT: ra-infra-shared-services-dev
# ============================================

# --- Habilitar APIs ---
resource "google_project_service" "infra_apis" {
  provider = google.infra_shared
  project  = "ra-infra-shared-services-dev"

  for_each = toset([
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  service            = each.value
  disable_on_destroy = false
}

# --- VPC Network ---
resource "google_compute_network" "ra_vpc_dev_001" {
  provider                = google.infra_shared
  name                    = "ra-vpc-dev-001"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  depends_on              = [google_project_service.infra_apis]
}

# --- Subnet ---
resource "google_compute_subnetwork" "example_subnet" {
  provider      = google.infra_shared
  name          = "ra-subnet-dev-001"
  ip_cidr_range = var.shared_vpc_cidr
  region        = var.region
  network       = google_compute_network.ra_vpc_dev_001.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.101.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.102.0.0/16"
  }
  private_ip_google_access = true
}

# --- Firewall Rules ---
resource "google_compute_firewall" "allow_internal" {
  provider = google.infra_shared
  name     = "ra-fw-allow-internal-dev-001"
  network  = google_compute_network.ra_vpc_dev_001.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = [var.shared_vpc_cidr, "10.101.0.0/16", "10.102.0.0/16"]
  priority      = 1000
}

resource "google_compute_firewall" "allow_iap_ssh" {
  provider = google.infra_shared
  name     = "ra-fw-allow-iap-ssh-dev-001"
  network  = google_compute_network.ra_vpc_dev_001.name
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000
}

resource "google_compute_firewall" "deny_external_egress" {
  provider  = google.infra_shared
  name      = "ra-fw-deny-external-egress-dev-001"
  network   = google_compute_network.ra_vpc_dev_001.name
  direction = "EGRESS"
  deny {
    protocol = "all"
  }
  destination_ranges = ["0.0.0.0/0"]
  priority           = 65534
}

resource "google_compute_firewall" "allow_google_apis_egress" {
  provider  = google.infra_shared
  name      = "ra-fw-allow-google-apis-egress-dev-001"
  network   = google_compute_network.ra_vpc_dev_001.name
  direction = "EGRESS"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  destination_ranges = ["199.36.153.8/30", "199.36.153.4/30"]
  priority           = 1000
}

# --- Cloud Router, NAT, Secret, Logging, Monitoring ---
resource "google_compute_router" "ra_rte_dev_001" {
  provider = google.infra_shared
  name     = "ra-rte-dev-001"
  region   = var.region
  network  = google_compute_network.ra_vpc_dev_001.id
}
resource "google_compute_address" "ra_ip_dev_001" {
  provider = google.infra_shared
  name     = "ra-ip-dev-001"
  region   = var.region
}
resource "google_compute_router_nat" "ra_nat_dev_001" {
  provider                       = google.infra_shared
  name                           = "ra-nat-dev-001"
  router                         = google_compute_router.ra_rte_dev_001.name
  region                         = google_compute_router.ra_rte_dev_001.region
  nat_ip_allocate_option         = "MANUAL_ONLY"
  nat_ips                        = [google_compute_address.ra_ip_dev_001.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.example_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
resource "google_secret_manager_secret" "ra_key_dev_001" {
  provider  = google.infra_shared
  secret_id = "ra-key-dev-001"
  replication {
    auto {}
  }
  depends_on = [google_project_service.infra_apis]
}
resource "google_secret_manager_secret_version" "ra_key_dev_001_v1" {
  provider    = google.infra_shared
  secret      = google_secret_manager_secret.ra_key_dev_001.id
  secret_data = "meu-valor-secreto-inicial-change-me"
}
resource "google_storage_bucket" "logging_bucket" {
  provider                    = google.infra_shared
  name                        = "ra-log-sink-dev-001"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}
resource "google_logging_project_sink" "ra_log_dev_001" {
  provider               = google.infra_shared
  name                   = "ra-log-dev-001"
  destination            = "storage.googleapis.com/${google_storage_bucket.logging_bucket.name}"
  filter                 = "logName:\"logs/cloudaudit.googleapis.com\""
  unique_writer_identity = true
}
resource "google_storage_bucket_iam_member" "log_bucket_writer" {
  provider = google.infra_shared
  bucket   = google_storage_bucket.logging_bucket.name
  role     = "roles/storage.objectCreator"
  member   = google_logging_project_sink.ra_log_dev_001.writer_identity
}
resource "google_monitoring_uptime_check_config" "ra_mon_dev_001" {
  provider     = google.infra_shared
  display_name = "ra-mon-dev-001-google-uptime"
  timeout      = "10s"
  period       = "60s"
  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "ra-infra-shared-services-dev"
      host       = "www.google.com"
    }
  }
  content_matchers {
    content = "Google"
    matcher = "CONTAINS_STRING"
  }
}