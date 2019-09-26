#!/bin/bash
set -e

if ibmcloud resource service-instance $COS_SERVICE_NAME > /dev/null 2>&1; then
  echo "Cloud Object Storage service $COS_SERVICE_NAME already exists"
else
  echo "Creating Cloud Object Storage Service..."
  ibmcloud resource service-instance-create $COS_SERVICE_NAME \
    cloud-object-storage "$COS_SERVICE_PLAN" global || exit 1
fi

COS_INSTANCE_ID=$(ibmcloud resource service-instance --output JSON $COS_SERVICE_NAME | jq -r .[0].id)
echo "Cloud Object Storage CRN is $COS_INSTANCE_ID"

if ibmcloud resource service-key $COS_SERVICE_NAME-for-functions; then
  echo "Service key already exists"
else
  ibmcloud resource service-key-create $COS_SERVICE_NAME-for-functions Writer --instance-id $COS_INSTANCE_ID
fi

# Create the bucket
if ibmcloud cos head-bucket --bucket $COS_BUCKET_NAME --region $COS_REGION > /dev/null 2>&1; then
  echo "Bucket already exists"
else
  echo "Creating storage bucket $COS_BUCKET_NAME"
  ibmcloud cos create-bucket \
    --bucket $COS_BUCKET_NAME \
    --ibm-service-instance-id $COS_INSTANCE_ID \
    --region $COS_REGION
fi

if ibmcloud resource service-instance $VISUAL_RECOGNITION_SERVICE_NAME; then
  echo "Visual Recognition service $VISUAL_RECOGNITION_SERVICE_NAME already exists"
else
  echo "Creating Visual Recognition Service..."
  ibmcloud resource service-instance-create $VISUAL_RECOGNITION_SERVICE_NAME \
    watson-vision-combined "$VISUAL_RECOGNITION_PLAN" $VISUAL_RECOGNITION_REGION || exit 1
fi

VISUAL_RECOGNITION_INSTANCE_ID=$(ibmcloud resource service-instance --output JSON $VISUAL_RECOGNITION_SERVICE_NAME | jq -r .[0].id)
echo "Visual Recognition CRN is $VISUAL_RECOGNITION_INSTANCE_ID"

if ibmcloud resource service-key $VISUAL_RECOGNITION_SERVICE_NAME-for-functions; then
  echo "Service key already exists"
else
  ibmcloud resource service-key-create $VISUAL_RECOGNITION_SERVICE_NAME-for-functions Manager --instance-id $VISUAL_RECOGNITION_INSTANCE_ID
fi
