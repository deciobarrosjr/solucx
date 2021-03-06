terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.69.0"
    }
    google-beta = {
      version = "~> 3.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

#
# Definindo as variáveis necessárias
#

variable "cred-file-path" {
  type        = string
  description = "Nome completo para localizacao do arquivo de credenciais da GSA usada."
  default     = "C:\\WORK\\solucx - Terraform\\prjdbjsolucx-gsa.json"
}

variable "yaml-file-path" {
  type        = string
  description = "Nome completo para localizacao o arquivo yaml usado no deployment."
}

variable "yaml-svc-path" {
  type        = string
  description = "Nome completo para localizacao do arquivo yaml usado para subir o helloworld."
}

variable "projeto" {
  type        = string
  description = "Nome do projeto onde sera efetuado o provisionamento pelo Terraform."
}

variable "regiao" {
  type        = string
  description = "Regio onde sera efetuado o provisionamento."
}

variable "zona" {
  type        = string
  description = "Zona onde sera efetuado o provisionamento."
}

variable "cluster" {
  type        = string
  description = "Nome do cluster a ser criado."
}

variable "gcp_service_list" {
  type        = list(string)
  description = "Lista das APIs a serem habilitadas."
}

variable "gsa" {
  type        = string
  description = "GSA to bind with the role cloudsql.client on the Workload Identity."
}

variable "ksa" {
  type        = string
  description = "KSA to bind with GSA on the Workload Identity."
}

variable "terraform-gsa" {
  type        = string
  description = "Nome da GSA a ser utilizada pelo Terraform."
}

#
# Importando os módulos necessários
#

provider "google" {
  credentials = file(var.cred-file-path)

  project = var.projeto
  region  = var.regiao
  zone    = var.zona
  alias   = "gb"
}

provider "google-beta" {
  credentials = file(var.cred-file-path)

  project = var.projeto
  region  = var.zona
  alias   = "gb3"
}

#
# Habilitando as APIs necessárias
#

resource "google_project_service" "gcp_services" {
  count                      = length(var.gcp_service_list)
  project                    = var.projeto
  disable_dependent_services = true

  service = var.gcp_service_list[count.index]
}

#
# Include the role to access the Container Registry to the GSA used to run Terraform
#

#resource "google_project_iam_binding" "gsa-terraform-container-bind" {
#  project = var.projeto
#  role    = "roles/resourcemanager.projectIamAdmin"
#  members = ["serviceAccount:${var.terraform-gsa}@prjdbjsolucx.iam.gserviceaccount.com"]

#  depends_on = [google_project_service.gcp_services]
#}

#
# Creates the cluster with Work Load Identity
#

resource "google_container_cluster" "my_cluster" {
  provider           = google-beta.gb3
  name               = var.cluster
  location           = var.zona
  initial_node_count = 3


  workload_identity_config {
    identity_namespace = "prjdbjsolucx.svc.id.goog"
  }

  node_config {
    service_account = "${var.terraform-gsa}@prjdbjsolucx.iam.gserviceaccount.com"
    machine_type    = "e2-medium"
    oauth_scopes = [
      #      "https://www.googleapis.com/auth/logging.write",
      #      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }
}

#
# Creates a GSA and bind the role "roles/cloudsql.client" to it
#

resource "google_service_account" "gsa-cloudsql" {
  project      = var.projeto
  account_id   = var.gsa
  display_name = "Helloworld GSA  for SQL proxy"
}

resource "google_project_iam_binding" "gsa-cloudsql-bind" {
  project = var.projeto
  role    = "roles/cloudsql.client"

  members = ["serviceAccount:${var.gsa}@prjdbjsolucx.iam.gserviceaccount.com"]

  depends_on = [google_service_account.gsa-cloudsql]
}

#
# Obtendo as credenciais de acesso ao cluster
#

data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  project  = var.projeto
  name     = var.cluster
  location = var.zona

  depends_on = [google_container_cluster.my_cluster]
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)

  load_config_file = false
}

#
# Cria um generic secret para armazenar a senha de acesso ao banco de dados
#

resource "kubernetes_secret" "sgw-config" {
  metadata {
    name = "dbjmysqlsecret"
  }

  data = {
    "username" = "root",
    "password" = "password123",
    "database" = "exemplo"
  }
  depends_on = [google_container_cluster.my_cluster]
}

#
# Cria uma KSA to bin with GSA that already have the role ""
#

resource "kubernetes_service_account" "example" {
  metadata {
    name      = var.ksa
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = "helloworld-gsa@prjdbjsolucx.iam.gserviceaccount.com"
    }
  }

  automount_service_account_token = true

  depends_on = [google_container_cluster.my_cluster]
}

#
# Enable the IAM binding between var.ksa and var.gsa
#

resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.gsa-cloudsql.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.projeto}.svc.id.goog[default/${var.ksa}]"
  ]
  depends_on = [google_container_cluster.my_cluster]
}

#
# Deploy the resources to the cluster
#

resource "kubectl_manifest" "my_deploy" {
  yaml_body  = file(var.yaml-file-path)
  depends_on = [google_container_cluster.my_cluster]
}

#
# Create the Hello World Service
#

resource "kubectl_manifest" "my_helloworl_service" {
  yaml_body = file(var.yaml-svc-path)

  depends_on = [kubectl_manifest.my_deploy]
}

#
# Exibe o endereço IP do serviço disponibilizado
#

resource "time_sleep" "msg-final" {

  create_duration = "120s"

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials helloworld-ter | kubectl get services"
  }

  depends_on = [kubectl_manifest.my_helloworl_service]
}




