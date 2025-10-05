# Quick Start Guide - Jenkins CI/CD with Docker

## Overview
This project now includes complete Docker and Jenkins CI/CD support for automated deployment to EC2.

## What's Been Added

1. **Dockerfile** - Multi-stage build for optimized Docker image
2. **docker-compose.yml** - Local development with PostgreSQL
3. **Jenkinsfile** - Complete CI/CD pipeline definition
4. **deploy.sh** - Deployment script for EC2
5. **.dockerignore** - Exclude unnecessary files from Docker build
6. **JENKINS_SETUP.md** - Detailed setup instructions

## Quick Test Locally

### Test with Docker Compose
```bash
# Build and run the entire stack (app + PostgreSQL)
docker-compose up --build

# Access the application
curl http://localhost:8080/api/users

# Stop the stack
docker-compose down
```

### Test Docker Build Only
```bash
# Build the Docker image
docker build -t jenkins-app:latest .

# Run the container (requires PostgreSQL running separately)
docker run -d \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=root \
  --network host \
  jenkins-app:latest
```

## CI/CD Flow

```
Developer Push → GitHub → Webhook → Jenkins → Build → Test → Docker Build → Deploy to EC2
```

### The Pipeline Does:
1. ✅ Checkout code from GitHub
2. ✅ Build with Maven
3. ✅ Run tests
4. ✅ Build Docker image
5. ✅ Push to registry (optional)
6. ✅ Deploy to EC2
7. ✅ Health check

## Setup Steps (High Level)

### 1. EC2 Setup (Target Server)
```bash
# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker ubuntu

# Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'root';"
```

### 2. Jenkins Setup
```bash
# Install Jenkins (on separate server or same EC2)
# Install required plugins:
# - Git, Pipeline, Docker Pipeline, SSH Agent, GitHub Integration

# Add credentials in Jenkins:
# - EC2 SSH key (ID: ec2-ssh-key)
# - GitHub credentials (optional)
# - Docker Hub credentials (optional)
```

### 3. Create Jenkins Pipeline Job
- New Item → Pipeline
- Configure GitHub repository
- Enable GitHub webhook trigger
- Point to Jenkinsfile in repo

### 4. Configure GitHub Webhook
- Repository Settings → Webhooks
- Add webhook: `http://YOUR_JENKINS_URL:8080/github-webhook/`

### 5. Test the Pipeline
```bash
# Make a change and push
git add .
git commit -m "Test CI/CD"
git push origin main

# Jenkins will automatically:
# - Detect the push
# - Run the pipeline
# - Deploy to EC2
```

## Environment Variables

The application uses these environment variables in production:

```bash
SPRING_PROFILES_ACTIVE=prod
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=root
```

## Monitoring

### Check Application Status
```bash
# On EC2
docker ps
docker logs jenkins-app -f

# Health check
curl http://localhost:8080/actuator/health
```

### Check Jenkins Build
- Go to Jenkins Dashboard
- Click on your pipeline
- View "Console Output" for logs

## Troubleshooting

### Docker Build Fails
```bash
# Check Docker is running
docker --version
sudo systemctl status docker

# Clean Docker cache
docker system prune -a
```

### Deployment Fails
```bash
# Check SSH connection
ssh ubuntu@34.234.71.223

# Check Docker on EC2
docker ps
docker logs jenkins-app

# Check PostgreSQL
sudo systemctl status postgresql
```

### Application Won't Start
```bash
# Check logs
docker logs jenkins-app

# Check database connection
docker exec -it jenkins-app sh
nc -zv localhost 5432
```

## Security Notes

⚠️ **Important**: The current setup uses hardcoded passwords for demonstration. For production:

1. Use AWS Secrets Manager or HashiCorp Vault
2. Use environment variables from secure storage
3. Enable HTTPS/SSL
4. Restrict security group rules
5. Use IAM roles instead of credentials
6. Implement proper authentication/authorization

## Next Steps

1. ✅ Code is pushed to GitHub
2. 📋 Follow JENKINS_SETUP.md for detailed setup
3. 🔧 Configure Jenkins server
4. 🚀 Set up webhook
5. 🎉 Enjoy automated deployments!

## Useful Commands

```bash
# View running containers
docker ps

# View logs
docker logs jenkins-app -f

# Stop container
docker stop jenkins-app

# Remove container
docker rm jenkins-app

# View images
docker images

# Clean up
docker system prune -a

# Restart application
docker restart jenkins-app
```

## API Endpoints

Once deployed, access your API at:
- `http://34.234.71.223:8080/api/users` - Get all users
- `http://34.234.71.223:8080/api/users/{id}` - Get user by ID
- `http://34.234.71.223:8080/actuator/health` - Health check

## Support

For detailed setup instructions, see **JENKINS_SETUP.md**
