#!/bin/bash

# Deployment script for EC2
# This script can be run manually or by Jenkins

set -e

APP_NAME="jenkins-app"
DOCKER_IMAGE="jenkins-app:latest"
CONTAINER_NAME="jenkins-app"

echo "Starting deployment..."

# Stop and remove existing container
echo "Stopping existing container..."
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# Pull or load the latest image
echo "Loading Docker image..."
# If using Docker Hub: docker pull $DOCKER_IMAGE

# Run the new container
echo "Starting new container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 8080:8080 \
    -e SPRING_PROFILES_ACTIVE=prod \
    -e SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres \
    -e SPRING_DATASOURCE_USERNAME=postgres \
    -e SPRING_DATASOURCE_PASSWORD=root \
    --network host \
    $DOCKER_IMAGE

# Wait for application to start
echo "Waiting for application to start..."
sleep 10

# Health check
echo "Performing health check..."
if curl -f http://localhost:8080/actuator/health; then
    echo "Deployment successful!"
else
    echo "Health check failed!"
    exit 1
fi

# Clean up old images
echo "Cleaning up old images..."
docker image prune -f

echo "Deployment completed successfully!"
