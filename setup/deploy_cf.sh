#!/bin/bash

#####################################################################################################
# Script Name: deploy_cf.sh
# Date of Creation: 2/26/2025
# Author: Ankur Wahi
# Updated: 2/26/2025
#####################################################################################################

source ./config.sh

cf_gemini="gemini-img-analysis"

echo "Deploying Gemini Img Analysis CF"

cd ~/gemini-on-bigquery/function/schema_image

gcloud functions deploy ${cf_gemini} --gen2 --region=${REGION} --runtime=python311 --entry-point=run_it --service-account=${gcf_sa} --run-service-account ${gcf_sa} --set-env-vars=PROJECT_ID=${PROJECT_ID},REGION=${REGION} --trigger-http --memory=256MB --allow-unauthenticated

endpoint_gemini=$(gcloud functions describe ${cf_gemini} --region=${REGION} --gen2 --format=json | jq -r '.serviceConfig.uri')

#Dummy job to fix this issue --> 'code': 400, 'message': 'Service agents are being provisioned (https://cloud.google.com/vertex-ai/docs/general/access-control#service-agents). Service agents are needed to read the Cloud Storage file provided. So please try again in a few minutes.', 'status': 'FAILED_PRECONDITION'
gcloud beta ai custom-jobs create --display-name test1 --region ${REGION} --worker-pool-spec=replica-count=1,machine-type=n1-highmem-2,container-image-uri=gcr.io/google-appengine/python

echo "Creating function.."
build_sql="CREATE OR REPLACE FUNCTION ${BQ_DATASET}.gemini_cf_remote(gcs_uri STRING,prompt STRING, response_schema STRING) RETURNS STRING REMOTE WITH  CONNECTION \`${PROJECT_ID}.${REGION}.${bq_ext_conn}\` OPTIONS (endpoint = '${endpoint_gemini}', max_batching_rows = 1)"
bq query --use_legacy_sql=false ${build_sql}

cd ~/gemini-on-bigquery/data
sleep 60
gsutil cp -r . gs://${bucket_name}

sleep 20
select_query="SELECT uri from ${BQ_DATASET}.gemini_obj_img limit 2"
bq query --use_legacy_sql=false ${select_query}