# Jenkins CI/CD Setup Guide

This guide will help you set up Jenkins for automated deployment of the Spring Boot application to EC2.

## Prerequisites

1. Jenkins server (can be on EC2 or separate server)
2. Docker installed on Jenkins server
3. Docker installed on EC2 target server
4. SSH access from Jenkins to EC2

## Part 1: EC2 Setup

### 1. Install Docker on EC2

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@34.234.71.223

# Update packages
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Log out and log back in for group changes to take effect
exit
```

### 2. Install PostgreSQL on EC2

```bash
# Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configure PostgreSQL
sudo -u postgres psql
\password postgres
(enter 'root' as password)
\q

# Update pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
# Change peer to md5 for local connections

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### 3. Configure Security Group

In AWS Console, add these inbound rules to your EC2 security group:
- Port 8080 (Application)
- Port 22 (SSH from Jenkins server)
- Port 5432 (PostgreSQL - only if needed externally)

## Part 2: Jenkins Server Setup

### 1. Install Jenkins

```bash
# Install Java
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 2. Install Docker on Jenkins Server

```bash
# Install Docker
sudo apt-get install -y docker.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### 3. Install Required Jenkins Plugins

1. Go to Jenkins Dashboard → Manage Jenkins → Plugins
2. Install these plugins:
   - **Git Plugin** (for GitHub integration)
   - **Pipeline Plugin** (for Jenkinsfile)
   - **Docker Pipeline Plugin** (for Docker commands)
   - **SSH Agent Plugin** (for SSH deployment)
   - **GitHub Integration Plugin** (for webhooks)

## Part 3: Configure Jenkins

### 1. Add EC2 SSH Credentials

1. Go to Jenkins Dashboard → Manage Jenkins → Credentials
2. Click on "System" → "Global credentials"
3. Click "Add Credentials"
4. Select "SSH Username with private key"
5. Configure:
   - ID: `ec2-ssh-key`
   - Username: `ubuntu`
   - Private Key: Paste your EC2 private key content
6. Click "Create"

### 2. Add Docker Hub Credentials (Optional)

If you want to use Docker Hub:
1. Go to Credentials → Add Credentials
2. Select "Username with password"
3. Configure:
   - ID: `dockerhub-credentials`
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password

### 3. Create Jenkins Pipeline Job

1. Click "New Item"
2. Enter name: `Jenkins-App-Deploy`
3. Select "Pipeline"
4. Click "OK"

5. Configure the pipeline:
   - **General**: Check "GitHub project" and enter: `https://github.com/swadhes/Jenkins`
   - **Build Triggers**: Check "GitHub hook trigger for GITScm polling"
   - **Pipeline**:
     - Definition: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: `https://github.com/swadhes/Jenkins.git`
     - Credentials: Add your GitHub credentials
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`

6. Click "Save"

## Part 4: Configure GitHub Webhook

1. Go to your GitHub repository: `https://github.com/swadhes/Jenkins`
2. Click "Settings" → "Webhooks" → "Add webhook"
3. Configure:
   - Payload URL: `http://YOUR_JENKINS_URL:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Select "Just the push event"
4. Click "Add webhook"

## Part 5: Test the Pipeline

### Manual Trigger
1. Go to Jenkins Dashboard
2. Click on your pipeline job
3. Click "Build Now"
4. Watch the build progress in "Console Output"

### Automatic Trigger
1. Make a change to your code
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. Jenkins will automatically trigger the build

## Part 6: Verify Deployment

1. Check if the application is running on EC2:
   ```bash
   ssh ubuntu@34.234.71.223
   docker ps
   curl http://localhost:8080/actuator/health
   ```

2. Access the application:
   - From browser: `http://34.234.71.223:8080/api/users`

## Troubleshooting

### Jenkins can't connect to EC2
- Verify SSH key is correct
- Check EC2 security group allows SSH from Jenkins server
- Test SSH manually: `ssh -i key.pem ubuntu@34.234.71.223`

### Docker permission denied
- Ensure jenkins user is in docker group: `sudo usermod -aG docker jenkins`
- Restart Jenkins: `sudo systemctl restart jenkins`

### Application can't connect to database
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check connection string in environment variables
- Ensure PostgreSQL accepts connections from localhost

### GitHub webhook not triggering
- Verify webhook URL is correct
- Check Jenkins is accessible from internet
- Review webhook delivery logs in GitHub

## Monitoring and Logs

### View application logs
```bash
docker logs jenkins-app -f
```

### View Jenkins logs
```bash
sudo tail -f /var/log/jenkins/jenkins.log
```

### View PostgreSQL logs
```bash
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

## Security Best Practices

1. Use environment variables for sensitive data
2. Don't commit passwords to Git
3. Use AWS Secrets Manager or HashiCorp Vault for production
4. Enable HTTPS for Jenkins
5. Restrict security group rules to specific IPs
6. Regularly update Jenkins and plugins
7. Use non-root user in Docker containers

## Next Steps

1. Set up monitoring (Prometheus, Grafana)
2. Configure log aggregation (ELK stack)
3. Add automated tests
4. Implement blue-green deployment
5. Set up backup strategy for database
6. Configure SSL/TLS certificates
