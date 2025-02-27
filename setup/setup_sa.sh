#!/bin/bash

#####################################################################################################
# Script Name: setup_sa.sh
# Date of Creation: 2/26/2025
# Author: Ankur Wahi
# Updated: 2/26/2025
#####################################################################################################



source ./config.sh
gcloud auth login ${USER_EMAIL}

echo "Assigning IAM Permissions"
gcloud config set project ${PROJECT_ID}

bq_ext_conn="bq_ext_conn"
##################################################
##
## Enable APIs
##
##################################################

echo "enabling the necessary APIs"

gcloud services enable compute.googleapis.com

gcloud services enable storage.googleapis.com

gcloud services enable bigquery.googleapis.com

gcloud services enable bigqueryconnection.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

gcloud services enable artifactregistry.googleapis.com

gcloud services enable run.googleapis.com

gcloud services enable cloudbuild.googleapis.com

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:${PROJECT_ID}"  --format='value(project_number)')



SERVICE_ACCOUNT=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com 
echo "Compute engine SA - ${SERVICE_ACCOUNT}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SERVICE_ACCOUNT} \
    --role=roles/serviceusage.serviceUsageAdmin \
    --role=roles/aiplatform.admin

sleep 15

# gcloud iam service-accounts keys create ~/eeKey.json --iam-account ${SERVICE_ACCOUNT}
# cd ~/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/ndvi/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/temperature/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/crop/

# Cloud function setup for EE

project_id=${PROJECT_ID}

gcf_sa=${SERVICE_ACCOUNT}

echo "GCF SA: ${gcf_sa}"


#Create the external connection for BQ
bq --location=${REGION} mk -d ${BQ_DATASET}

bq mk --connection --display_name='gcf_ext_conn' \
      --connection_type=CLOUD_RESOURCE \
      --project_id=$(gcloud config get-value project) \
      --location=${REGION}  ${bq_ext_conn}

#Get serviceAccountID associated with the connection  

serviceAccountId=`bq show --location=${REGION} --connection --format=json  ${bq_ext_conn}| jq -r '.cloudResource.serviceAccountId'`
echo "Service Account: ${serviceAccountId}"

# Add Cloud run admin
gcloud projects add-iam-policy-binding \
$(gcloud config get-value project) \
--member='serviceAccount:'${serviceAccountId} \
--role='roles/run.admin' \
--role='roles/storage.objectViewer'

gcloud projects add-iam-policy-binding  \
$(gcloud config get-value project) \
--member='serviceAccount:'${gcf_sa} \
--role=roles/cloudbuild.builds.builder

bucket_name=${RANDOM}-${PROJECT_ID}

tbl_def="gs://${bucket_name}/*@${REGION}.${bq_ext_conn}"

gcloud storage buckets create gs://${bucket_name} --location=${REGION}

bq mk --table \
--external_table_definition=${tbl_def} \
--object_metadata=SIMPLE  \
${PROJECT_ID}:${BQ_DATASET}.gemini_obj_img

echo "export gcf_sa=${gcf_sa}" >> ~/gemini-on-bigquery/setup/config.sh
echo "export bucket_name=${bucket_name}" >> ~/gemini-on-bigquery/setup/config.sh
echo "export bq_ext_conn=${bq_ext_conn}" >> ~/gemini-on-bigquery/setup/config.sh

