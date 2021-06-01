##############################################################     HELLO WORLD     ##############################################################

Este programa Hello World foi criado conforme as especifições detalahdas em: Infraestrutura em Cloud.pdf

Criei duas versões do procedimento: a primeira e mais indicada usando Work Load Identity e a segunda
usando Key File.

Os scripts, das duas versões, estão aqui detalhados, no entando, gerei duas versões em pdf com os
procedimentos mais detalhados e ilustrados para melhor entendimento:

1: WorkLoadIdentity.pdf
2: KeyFile.pdf

Foram criadas as seguintes aplicações em Python:

app.py - código contendo a aplicação final Hello World conforme solicitado.
app_basic.py - código contendo um Hello World básico sem acesso ao banco de dados.
app_env.py - aplicação para verificar variáveis de ambiente.

A seguir os comandos das duas versões:

#####     Work Load Identity ###################################################################################################################

Change to the source folder of the project downloaded from Git.
Execute the Google Cloud SDK Shell as administrator

gcloud config configurations create deciocfg
gcloud auth login

gcloud projects create prjdbjsolucx --name prjdbjsolucx
gcloud config set project prjdbjsolucx

gcloud services enable cloudbuild.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable iamcredentials.googleapis.com
gcloud services enable stackdriver.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable deploymentmanager.googleapis.com

gcloud sql instances create dbjmysql --database-version=MYSQL_5_7 --cpu=2 --memory=8GB  --zone=us-central1-a --root-password=password123

gcloud sql connect dbjmysql --user=root

mysql> create database exemplo\g
mysql> use exemplo\g
mysql>  	create table tabela(
   	linha INT NOT NULL AUTO_INCREMENT,
   	mensagem VARCHAR(100) NOT NULL,
   	PRIMARY KEY ( linha )
		)\g
mysql> insert into tabela (mensagem) VALUES (“Hello World!”)\g
mysql> exit

gcloud sql instances patch dbjmysql --availability-type REGIONAL --enable-bin-log --backup-start-time=04:00

gcloud components install kubectl

gcloud builds submit --tag gcr.io/prjdbjsolucx/helloworld-gke .

gcloud config set project prjdbjsolucx
gcloud config set compute/region us-central1
gcloud config set compute/zone  us-central1-a

gcloud container clusters create helloworld-gke --workload-pool=prjdbjsolucx.svc.id.goog

gcloud container clusters get-credentials helloworld-gke

kubectl create secret generic dbjmysqlsecret --from-literal=username=root --from-literal=password=password123 --from-literal=database=exemplo

kubectl apply -f service-account.yaml

gcloud iam service-accounts create helloworld-gsa --display-name="Helloworld GSA  for SQL proxy" 
gcloud projects add-iam-policy-binding prjdbjsolucx --member="serviceAccount:helloworld-gsa@prjdbjsolucx.iam.gserviceaccount.com" --role=”roles/cloudsql.client”

gcloud iam service-accounts add-iam-policy-binding --role roles/iam.workloadIdentityUser --member "serviceAccount:prjdbjsolucx.svc.id.goog[default/helloworld-gke-ksa]" helloworld-gsa@prjdbjsolucx.iam.gserviceaccount.com

kubectl annotate serviceAccount --namespace default helloworld-gke-ksa iam.gke.io/gcp-service-account=helloworld-gsa@prjdbjsolucx.iam.gserviceaccount.com

kubectl apply -f deployment-wli.yaml

kubectl get deployments

kubectl apply -f service.yaml

kubectl get services


#####     Key File           ###################################################################################################################


Change to the source folder of the project downloaded from Git.
Execute the Google Cloud SDK Shell as administrator

gcloud config configurations create deciocfg
gcloud auth login

gcloud projects create prjdbjsolucx --name prjdbjsolucx
gcloud config set project prjdbjsolucx

gcloud services enable cloudbuild.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable iamcredentials.googleapis.com
gcloud services enable stackdriver.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable deploymentmanager.googleapis.com

gcloud sql instances create dbjmysql --database-version=MYSQL_5_7 --cpu=2 --memory=8GB  --zone=us-central1-a --root-password=password123

gcloud sql connect dbjmysql --user=root

mysql> create database exemplo\g
mysql> use exemplo\g
mysql>  	create table tabela(
   	linha INT NOT NULL AUTO_INCREMENT,
   	mensagem VARCHAR(100) NOT NULL,
   	PRIMARY KEY ( linha )
		)\g
mysql> insert into tabela (mensagem) VALUES (“Hello World!”)\g
mysql> exit

gcloud sql instances patch dbjmysql --availability-type REGIONAL --enable-bin-log --backup-start-time=04:00

gcloud components install kubectl

gcloud builds submit --tag gcr.io/prjdbjsolucx/helloworld-gke .

gcloud config set project prjdbjsolucx
gcloud config set compute/region us-central1
gcloud config set compute/zone  us-central1-a

gcloud container clusters create helloworld-gke 

gcloud iam service-accounts create helloworld-gsa --display-name="Helloworld GSA  for SQL proxy" 
gcloud projects add-iam-policy-binding prjdbjsolucx --member="serviceAccount:helloworld-gsa@prjdbjsolucx.iam.gserviceaccount.com" --role=”roles/cloudsql.client”

gcloud iam service-accounts keys create key.json --iam-account helloworld-gsa@prjdbjsolucx.iam.gserviceaccount.com 

kubectl create secret generic deciomysasecret --from-file=credentials.json=key.json

kubectl create secret generic dbjmysqlsecret --from-literal=username=root --from-literal=password=password123 --from-literal=database=exemplo

kubectl apply -f deployment-kf.yaml

kubectl get deployments

kubectl apply -f service.yaml

kubectl get services








