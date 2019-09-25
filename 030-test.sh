#!/bin/bash
set -e

# Photo by Jason Garcia on Unsplash https://unsplash.com/@jasunfilms?utm_medium=referral&utm_campaign=photographer-credit&utm_content=creditBadge
wget -O an-image.jpg "https://images.unsplash.com/photo-1569267773522-0c270c9c4466?ixlib=rb-1.2.1&q=85&fm=jpg&crop=entropy&cs=srgb&dl=jason-garcia-s3pUjUNj9YU-unsplash.jpg"

echo "Listing objects Before uploading the image..."
ibmcloud cos list-objects --bucket $COS_BUCKET_NAME --region $REGION --json | jq -r '.Contents[]? | .Key'

echo "Uploading image"
ibmcloud cos upload --bucket $COS_BUCKET_NAME --region $REGION --key an-image.jpg --file an-image.jpg

ibmcloud fn activation poll -e 10

echo "Listing objects after uploading the image..."
ibmcloud cos list-objects --bucket $COS_BUCKET_NAME --region $REGION --json | jq -r '.Contents[] | .Key'
