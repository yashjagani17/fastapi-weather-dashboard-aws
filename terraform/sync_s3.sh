#!/bin/bash

BUCKET_NAME=$(terraform output -raw primary_bucket_name)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)
LOCAL_FOLDER="../web/"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: could not find terraform outputs. Did you run terraform apply?"
    exit 1
fi

echo "Deploying to S3 Bucket: $BUCKET_NAME"
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"

aws s3 sync $LOCAL_FOLDER s3://$BUCKET_NAME/ --delete
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"

echo "Successfully deployed '$LOCAL_FOLDER' to '$BUCKET_NAME'!"