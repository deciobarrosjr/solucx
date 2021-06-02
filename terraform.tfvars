projeto       = "prjdbjsolucx"
regiao        = "us-central1"
zona          = "us-central1-a"
banco-dados   = "dbjmysql21"
cluster       = "helloworld-ter"
ksa           = "helloworld-gke-ksa"
gsa           = "helloworld-gsa"
terraform-gsa = "terraform-gsa"

gcp_service_list = [
  "cloudbuild.googleapis.com",
  "container.googleapis.com",
  "sqladmin.googleapis.com",
  "iamcredentials.googleapis.com",
  "stackdriver.googleapis.com",
  "compute.googleapis.com",
  "deploymentmanager.googleapis.com",
  "secretmanager.googleapis.com"
]
