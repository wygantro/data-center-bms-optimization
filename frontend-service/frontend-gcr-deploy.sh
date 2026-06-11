#!/bin/bash

# Exit immediately on error
set -e

# Config
PROJECT_ID="opendeed-reports-460220"
REGION="us-central1"
REPOSITORY="opendeed-reports-repo"
SERVICE_NAME="opendeed-reports-frontend-test-service"
IMAGE_NAME="opendeed-reports-frontend-test"
TAG="latest"
FULL_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${TAG}"

echo "Configuring Docker to authenticate with Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

echo "Building Docker image..."
docker build -t "${IMAGE_NAME}" .

echo "Tagging image as ${FULL_IMAGE}..."
docker tag "${IMAGE_NAME}" "${FULL_IMAGE}"

echo "Pushing image to Artifact Registry..."
docker push "${FULL_IMAGE}"

echo "Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${FULL_IMAGE}" \
  --platform managed \
  --region "${REGION}" \
  --allow-unauthenticated \
  --quiet

echo "✅ Deployment complete: ${SERVICE_NAME} is live."