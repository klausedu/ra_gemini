variable "region" {
  description = "A região padrão do GCP para implantar recursos."
  type        = string
  default     = "us-central1"
}

variable "organization_id" {
  description = "ID da organização do GCP"
  type        = string
  default     = "RicardoAlmeida" # Substitua se necessário
}

# --- VARIÁVEIS DE IAM ---

variable "infra_admins_group" {
  description = "Email do grupo de admins de infra (DEV)."
  type        = string
  default     = "" # "group:grp-iam-dev-infra-admins@ricardoalmeida.com.br"
}

variable "data_admins_group" {
  description = "Email do grupo de admins de dados (DEV)."
  type        = string
  default     = "" # "group:grp-iam-dev-data-admins@ricardoalmeida.com.br"
}

variable "readers_group" {
  description = "Email do grupo de leitores (DEV)."
  type        = string
  default     = "" # "group:grp-ra-iam-dev-readers@ricardoalmeida.com.br"
}

# --- VARIÁVEIS DE REDE ---

variable "shared_vpc_cidr" {
  description = "CIDR da subnet principal da Shared VPC"
  type        = string
  default     = "10.100.0.0/24"
}