#!/bin/bash

# Cloud Functions
ibmcloud fn rule delete create-rule
ibmcloud fn trigger delete create-trigger
ibmcloud fn action delete thumbnail
ibmcloud fn action delete visualrecognition
ibmcloud fn action delete on-create
ibmcloud fn action delete filter

ibmcloud fn rule delete delete-rule
ibmcloud fn trigger delete delete-trigger
ibmcloud fn action delete on-delete

NAMESPACE=$PREFIX-actions
ibmcloud fn namespace delete $NAMESPACE

# COS
ibmcloud cos delete-bucket --bucket $COS_BUCKET_NAME --region $REGION --force
ibmcloud resource service-key-delete $COS_SERVICE_NAME-for-functions --force
COS_INSTANCE_ID=$(ibmcloud resource service-instance --output JSON $COS_SERVICE_NAME | jq -r .[0].id)
ibmcloud resource service-instance-delete $COS_INSTANCE_ID --force

VISUAL_RECOGNITION_INSTANCE_ID=$(ibmcloud resource service-instance --output JSON $VISUAL_RECOGNITION_SERVICE_NAME | jq -r .[0].id)
ibmcloud resource service-instance-delete $VISUAL_RECOGNITION_INSTANCE_ID --force --recursive
