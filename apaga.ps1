<# 
 ==============================================================================
 SCRIPT DE LIMPEZA DE CONTEÚDO (NÃO APAGA PROJETOS)
 
 ⚠️ AVISO: Este script irá APAGAR PERMANENTEMENTE todos os recursos
          criados pelo Terraform DENTRO dos 3 projetos.
 ==============================================================================
#>

# Configura o script para parar imediatamente se um comando falhar
$ErrorActionPreference = "Stop"

# --- 1. Definição das Variáveis (Baseado nos seus .tf) ---
$HostProject = "ra-infra-shared-services-dev"
$DataProject = "ra-data-pipeline-dev"
$AnalyticsProject = "ra-analytics-dev-474600"
$Region = "us-central1"

Write-Host "======================================================================"
Write-Host "PASSO 1: Excluindo recursos 'consumidores' da Shared VPC" -ForegroundColor Yellow
Write-Host "Isso é necessário antes de desanexar a VPC."
Write-Host "======================================================================"

# Usamos Try/Catch para ignorar erros caso os recursos já tenham sido excluídos
try {
    Write-Host "Excluindo cluster Dataproc 'ra-dataproc-cluster-dev-001'..."
    gcloud dataproc clusters delete ra-dataproc-cluster-dev-001 --project=$AnalyticsProject --region=$Region --quiet
} catch {
    Write-Warning "Falha ao excluir cluster (provavelmente já excluído): $($_.Exception.Message)"
}

try {
    Write-Host "Excluindo Cloud Function 'ra-fnc-dev-001'..."
    gcloud functions delete ra-fnc-dev-001 --project=$DataProject --region=$Region --quiet
} catch {
    Write-Warning "Falha ao excluir Cloud Function 'ra-fnc-dev-001' (provavelmente já excluída): $($_.Exception.Message)"
}

try {
    Write-Host "Excluindo Cloud Function 'ra-fnc-dev-002'..."
    gcloud functions delete ra-fnc-dev-002 --project=$DataProject --region=$Region --quiet
} catch {
    Write-Warning "Falha ao excluir Cloud Function 'ra-fnc-dev-002' (provavelmente já excluída): $($_.Exception.Message)"
}

Write-Host "Recursos de compute removidos." -ForegroundColor Green

Write-Host "======================================================================"
Write-Host "PASSO 2: Desabilitando a Shared VPC (O Bloqueador Principal)" -ForegroundColor Yellow
Write-Host "(Projeto: $HostProject)"
Write-Host "======================================================================"

# Estes comandos DEVEM funcionar, então não usamos Try/Catch
Write-Host "Desanexando projeto $DataProject..."
gcloud compute shared-vpc disable-project-service $DataProject --host-project=$HostProject --quiet

Write-Host "Desanexando projeto $AnalyticsProject..."
gcloud compute shared-vpc disable-project-service $AnalyticsProject --host-project=$HostProject --quiet

Write-Host "Desabilitando o Host Project..."
gcloud compute shared-vpc disable $HostProject --quiet

Write-Host "Shared VPC desabilitada e projetos desanexados." -ForegroundColor Green

Write-Host "======================================================================"
Write-Host "PASSO 3: Excluindo a Rede VPC (Infra Project)" -ForegroundColor Yellow
Write-Host "======================================================================"

# A ordem de exclusão da rede é crítica: NAT -> Router -> Regras -> Subnet -> Network
# Usamos Try/Catch para cada etapa, pois podem já ter sido excluídos
try {
    Write-Host "Excluindo NAT 'ra-nat-dev-001'..."
    gcloud compute routers nats delete ra-nat-dev-001 --router=ra-rte-dev-001 --project=$HostProject --region=$Region --quiet
} catch { Write-Warning "Falha ao excluir NAT: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Router 'ra-rte-dev-001'..."
    gcloud compute routers delete ra-rte-dev-001 --project=$HostProject --region=$Region --quiet
} catch { Write-Warning "Falha ao excluir Router: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo IP 'ra-ip-dev-001'..."
    gcloud compute addresses delete ra-ip-dev-001 --project=$HostProject --region=$Region --quiet
} catch { Write-Warning "Falha ao excluir IP: $($_.Exception.Message)" }

try { Write-Host "Excluindo regra de firewall 'ra-fw-allow-internal-dev-001'..."
    gcloud compute firewall-rules delete ra-fw-allow-internal-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir firewall: $($_.Exception.Message)" }
try { Write-Host "Excluindo regra de firewall 'ra-fw-allow-iap-ssh-dev-001'..."
    gcloud compute firewall-rules delete ra-fw-allow-iap-ssh-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir firewall: $($_.Exception.Message)" }
try { Write-Host "Excluindo regra de firewall 'ra-fw-deny-external-egress-dev-001'..."
    gcloud compute firewall-rules delete ra-fw-deny-external-egress-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir firewall: $($_.Exception.Message)" }
try { Write-Host "Excluindo regra de firewall 'ra-fw-allow-google-apis-egress-dev-001'..."
    gcloud compute firewall-rules delete ra-fw-allow-google-apis-egress-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir firewall: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Subnet 'ra-subnet-dev-001'..."
    gcloud compute networks subnets delete ra-subnet-dev-001 --project=$HostProject --region=$Region --quiet
} catch { Write-Warning "Falha ao excluir Subnet: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Rede VPC 'ra-vpc-dev-001'..."
    gcloud compute networks delete ra-vpc-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir VPC: $($_.Exception.Message)" }

Write-Host "Recursos de rede excluídos." -ForegroundColor Green

Write-Host "======================================================================"
Write-Host "PASSO 4: Excluindo todos os outros recursos (Buckets, BQ, Secrets...)" -ForegroundColor Yellow
Write-Host "======================================================================"

try { Write-Host "Excluindo Bucket 'ra-stg-functions-dev-001'..."
    gcloud storage rm --recursive gs://ra-stg-functions-dev-001
} catch { Write-Warning "Falha ao excluir Bucket: $($_.Exception.Message)" }
try { Write-Host "Excluindo Bucket 'ra-sa-dev-001'..."
    gcloud storage rm --recursive gs://ra-sa-dev-001
} catch { Write-Warning "Falha ao excluir Bucket: $($_.Exception.Message)" }
try { Write-Host "Excluindo Bucket 'ra-stg-dataproc-dev-001'..."
    gcloud storage rm --recursive gs://ra-stg-dataproc-dev-001
} catch { Write-Warning "Falha ao excluir Bucket: $($_.Exception.Message)" }
try { Write-Host "Excluindo Bucket 'ra-tmp-dataproc-dev-001'..."
    gcloud storage rm --recursive gs://ra-tmp-dataproc-dev-001
} catch { Write-Warning "Falha ao excluir Bucket: $($_.Exception.Message)" }
try { Write-Host "Excluindo Bucket 'ra-log-sink-dev-001'..."
    gcloud storage rm --recursive gs://ra-log-sink-dev-001
} catch { Write-Warning "Falha ao excluir Bucket: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Dataset BigQuery 'ra_bq_dev_001'..."
    bq rm -f --dataset "$($AnalyticsProject):ra_bq_dev_001"
} catch { Write-Warning "Falha ao excluir Dataset BQ: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Data Catalog Template 'ra_dts_dev_001'..."
    gcloud data-catalog tag-templates delete ra_dts_dev_001 --project=$AnalyticsProject --location=$Region --quiet
} catch { Write-Warning "Falha ao excluir Data Catalog: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Secret 'ra-key-dev-001'..."
    gcloud secrets delete ra-key-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir Secret: $($_.Exception.Message)" }

try {
    Write-Host "Excluindo Log Sink 'ra-log-dev-001'..."
    gcloud logging sinks delete ra-log-dev-001 --project=$HostProject --quiet
} catch { Write-Warning "Falha ao excluir Log Sink: $($_.Exception.Message)" }

try {
    # ID do Uptime Check pego do seu .tfstate
    Write-Host "Excluindo Uptime Check 'ra-mon-dev-001-google-uptime-oZQDkL7cV28'..."
    gcloud monitoring uptime-checks delete "projects/$HostProject/uptimeCheckConfigs/ra-mon-dev-001-google-uptime-oZQDkL7cV28" --quiet
} catch { Write-Warning "Falha ao excluir Uptime Check: $($_.Exception.Message)" }

Write-Host "======================================================================"
Write-Host "PASSO 5: Zerando o estado local do Terraform" -ForegroundColor Yellow
Write-Host "======================================================================"

if (Test-Path "terraform.tfstate") {
    Remove-Item "terraform.tfstate"
    Write-Host "Arquivo 'terraform.tfstate' excluído." -ForegroundColor Green
} else {
    Write-Host "Arquivo 'terraform.tfstate' não encontrado."
}

if (Test-Path "terraform.tfstate.backup") {
    Remove-Item "terraform.tfstate.backup"
    Write-Host "Arquivo 'terraform.tfstate.backup' excluído." -ForegroundColor Green
}

Write-Host "======================================================================"
Write-Host "SUCESSO: Limpeza de conteúdo concluída." -ForegroundColor Cyan
Write-Host "Os projetos ainda existem, mas os recursos foram excluídos."
Write-Host "Agora você pode executar 'terraform init' e 'terraform apply' novamente."
Write-Host "======================================================================"