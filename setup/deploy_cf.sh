#!/bin/bash

#####################################################################################################
# Script Name: deploy_cf.sh
# Date of Creation: 2/26/2025
# Author: Ankur Wahi
# Updated: 2/26/2025
#####################################################################################################

source ./config.sh

project_id=${PROJECT_ID}
cf_gemini="gemini-img-anlaysis"

echo "Deploying Gemini Img Analysis CF"

cd ~/gemini-on-bigquery/function/schema_image

gcloud functions deploy ${cf_gemini} --entry-point run_it --runtime python311 --trigger-http --allow-unauthenticated --set-env-vars SERVICE_ACCOUNT=${gcf_sa} --project ${project_id} --service-account ${gcf_sa} --gen2 --region ${REGION} --run-service-account ${gcf_sa} --memory 256MB




endpoint_gemini=$(gcloud functions describe ${cf_ndvi} --region=${REGION} --gen2 --format=json | jq -r '.serviceConfig.uri')



    
# build_sql="CREATE OR REPLACE FUNCTION gee.get_ndvi_month(lon float64,lat float64, farm_name STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint}')"

build_sql="CREATE OR REPLACE FUNCTION gee.get_poly_ndvi_month(aoi STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint_gemini}')"
    
bq query --use_legacy_sql=false ${build_sql}





#bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=lon:FLOAT,lat:FLOAT,name:STRING ${project_id}:gee.land_coords  ./land_point.csv 

#bq query --use_legacy_sql=false 'SELECT gee.get_ndvi_month(lon,lat,name,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'




gcloud storage buckets create gs://${bucket_name} --location=${REGION}
cd ~/gemini-on-bigquery/data
sleep 60
gsutil cp . gs://${bucket_name}

#bq query --use_legacy_sql=false 'SELECT gee.get_poly_ndvi_month(farm_aoi,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'
bq query --use_legacy_sql=false 'SELECT * from `gee.land_coords` LIMIT 10'