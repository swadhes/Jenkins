pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'jenkins-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        EC2_HOST = '34.234.71.223'
        EC2_USER = 'ubuntu'
        APP_NAME = 'jenkins-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application with Maven...'
                sh './mvnw clean package -DskipTests'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Skipping tests...'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Push to Docker Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    // If using Docker Hub, uncomment and configure:
                    // withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                    //                                   usernameVariable: 'DOCKER_USER', 
                    //                                   passwordVariable: 'DOCKER_PASS')]) {
                    //     sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    //     sh "docker push ${DOCKER_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                    //     sh "docker push ${DOCKER_USER}/${DOCKER_IMAGE}:latest"
                    // }
                    
                    // For now, we'll save the image as a tar file
                    sh "docker save ${DOCKER_IMAGE}:latest -o ${DOCKER_IMAGE}.tar"
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo 'Deploying to EC2...'
                script {
                    // Copy docker image to EC2
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            scp -o StrictHostKeyChecking=no ${DOCKER_IMAGE}.tar ${EC2_USER}@${EC2_HOST}:/home/${EC2_USER}/
                            
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                # Load the Docker image
                                docker load -i /home/${EC2_USER}/${DOCKER_IMAGE}.tar
                                
                                # Stop and remove old container if exists
                                docker stop ${APP_NAME} || true
                                docker rm ${APP_NAME} || true
                                
                                # Run new container
                                docker run -d \
                                    --name ${APP_NAME} \
                                    --restart unless-stopped \
                                    -p 8080:8080 \
                                    -e SPRING_PROFILES_ACTIVE=prod \
                                    -e SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres \
                                    -e SPRING_DATASOURCE_USERNAME=postgres \
                                    -e SPRING_DATASOURCE_PASSWORD=root \
                                    --network host \
                                    ${DOCKER_IMAGE}:latest
                                
                                # Clean up
                                rm /home/${EC2_USER}/${DOCKER_IMAGE}.tar
                                docker image prune -f
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            // You can add notifications here (Slack, Email, etc.)
        }
        failure {
            echo 'Pipeline failed!'
            // You can add failure notifications here
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
