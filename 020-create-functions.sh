#!/bin/bash
set -e

NAMESPACE=$PREFIX-actions
if ibmcloud fn namespace get $NAMESPACE > /dev/null 2>&1; then
  echo "Namespace $NAMESPACE already exists."
else
  ibmcloud fn namespace create $NAMESPACE
fi

NAMESPACE_INSTANCE_ID=$(ibmcloud fn namespace get $NAMESPACE --properties | grep ID | awk '{print $2}')
ibmcloud fn property set --namespace $NAMESPACE_INSTANCE_ID
echo "Namespace Instance ID is $NAMESPACE_INSTANCE_ID"

COS_GUID=$(ibmcloud resource service-instance --output JSON $COS_SERVICE_NAME | jq -r .[0].guid)
echo "COS GUI is $COS_GUID"

EXISTING_POLICIES=$(ibmcloud iam authorization-policies --output JSON)
if echo "$EXISTING_POLICIES" | \
  jq -e '.[] |
  select(.subjects[].attributes[].value=="functions") |
  select(.subjects[].attributes[].value=="'$NAMESPACE_INSTANCE_ID'") |
  select(.roles[].display_name=="Notifications Manager") |
  select(.resources[].attributes[].value=="cloud-object-storage") |
  select(.resources[].attributes[].value=="'$COS_GUID'")' > /dev/null; then
  echo "Reader policy between Functions and COS already exists"
else
  ibmcloud iam authorization-policy-create functions \
    cloud-object-storage "Notifications Manager" \
    --source-service-instance-name $NAMESPACE \
    --target-service-instance-id $COS_GUID
fi

# a simple filter action to ignore unrelated events
ibmcloud fn action update filter \
  actions/event-filter.js

# get the key to access to the service
COS_SERVICE_KEY=$(ibmcloud resource service-key $COS_SERVICE_NAME-for-functions --output json)
COS_API_KEY=$(echo $COS_SERVICE_KEY | jq -r .[0].credentials.apikey)
COS_INSTANCE_ID=$(echo $COS_SERVICE_KEY | jq -r .[0].credentials.resource_instance_id)

VISUAL_RECOGNITION_SERVICE_KEY=$(ibmcloud resource service-key $VISUAL_RECOGNITION_SERVICE_NAME-for-functions --output json)
VISUAL_RECOGNITION_API_KEY=$(echo $VISUAL_RECOGNITION_SERVICE_KEY | jq -r .[0].credentials.apikey)
VISUAL_RECOGNITION_URL=$(echo $VISUAL_RECOGNITION_SERVICE_KEY | jq -r .[0].credentials.url)

# one trigger, action sequence and rule to handle new images
if ibmcloud fn trigger get create-trigger > /dev/null 2>&1; then
  echo "Trigger on create already exists"
else
  ibmcloud fn trigger create create-trigger --feed /whisk.system/cos/changes \
    --param bucket $COS_BUCKET_NAME \
    --param event_types create
fi

ibmcloud fn action update thumbnail \
  --param cosApiKey $COS_API_KEY \
  --param cosInstanceId $COS_INSTANCE_ID \
  actions/thumbnail.js

ibmcloud fn action update visualrecognition \
  --param cosApiKey $COS_API_KEY \
  --param cosInstanceId $COS_INSTANCE_ID \
  --param vrUrl $VISUAL_RECOGNITION_URL \
  --param vrApiKey $VISUAL_RECOGNITION_API_KEY \
  actions/visualrecognition.js

ibmcloud fn action update on-create \
  filter,thumbnail,visualrecognition \
  --sequence

if ibmcloud fn rule get create-rule > /dev/null 2>&1; then
  echo "Rule already exists"
else
  ibmcloud fn rule create create-rule create-trigger on-create
fi

# one trigger, action sequence and rule to handle the deletion of images
if ibmcloud fn trigger get delete-trigger > /dev/null 2>&1; then
  echo "Trigger on create already exists"
else
  ibmcloud fn trigger create delete-trigger --feed /whisk.system/cos/changes \
    --param bucket $COS_BUCKET_NAME \
    --param event_types delete
fi

ibmcloud fn action update delete \
  --param cosApiKey $COS_API_KEY \
  --param cosInstanceId $COS_INSTANCE_ID \
  actions/delete.js

ibmcloud fn action update on-delete \
  filter,delete \
  --sequence

if ibmcloud fn rule get delete-rule > /dev/null 2>&1; then
  echo "Rule already exists"
else
  ibmcloud fn rule create delete-rule delete-trigger on-delete
fi
