#!/bin/bash

REPO_URL=$(terraform output -raw ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
REGION="eu-west-2"

echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URL

echo "Building Docker image..."
docker build --platform linux/amd64 -t weather-backend ..

echo "Tagging image..."
docker tag weather-backend:latest $REPO_URL:latest

echo "Pushing image to ECR..."
docker push $REPO_URL:latest

echo "Image pushed successfully"

echo "Forcing new ECS deployment with the changes"
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $REGION

echo "Deployment successful"