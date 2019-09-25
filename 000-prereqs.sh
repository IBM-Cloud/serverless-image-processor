#!/bin/bash
set -e

echo ">>> Targeting region $REGION..."
ibmcloud target -r $REGION

echo ">>> Targeting resource group $RESOURCE_GROUP_NAME..."
ibmcloud target -g $RESOURCE_GROUP_NAME

echo ">>> Ensuring Cloud Object Storage plugin is installed"
if ibmcloud cos config list >/dev/null; then
  echo "cloud-object-storage plugin is OK"
  # clear any default crn as it could prevent COS calls to work
  ibmcloud cos config crn --crn "" --force
else
  echo "Make sure cloud-object-storage plugin is properly installed with ibmcloud plugin install cloud-object-storage."
  exit 1
fi

echo ">>> Ensuring Cloud Functions plugin is installed"
if ibmcloud fn list >/dev/null; then
  echo "cloud-functions plugin is OK"
else
  echo "Make sure cloud-functions plugin is properly installed with ibmcloud plugin install cloud-functions."
  exit 1
fi

echo ">>> Is jq (https://stedolan.github.io/jq/) installed?"
jq -V
