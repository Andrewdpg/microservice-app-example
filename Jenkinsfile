pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'andrewdpg'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBECONFIG = '/var/jenkins_home/.kube/config'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build and Push Images') {
            parallel {
                stage('Auth API') {
                    steps {
                        dir('auth-api') {
                            script {
                                // Usar el plugin de Docker en lugar de withDockerRegistry
                                def image = docker.build("${DOCKER_REGISTRY}/auth-api:${IMAGE_TAG}")
                                docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                                    image.push()
                                    image.push("latest")
                                }
                            }
                        }
                    }
                }
                
                stage('Users API') {
                    steps {
                        dir('users-api') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/users-api:${IMAGE_TAG}")
                                docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                                    image.push()
                                    image.push("latest")
                                }
                            }
                        }
                    }
                }
                
                stage('TODOs API') {
                    steps {
                        dir('todos-api') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/todos-api:${IMAGE_TAG}")
                                docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                                    image.push()
                                    image.push("latest")
                                }
                            }
                        }
                    }
                }
                
                stage('Log Processor') {
                    steps {
                        dir('log-message-processor') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/log-processor:${IMAGE_TAG}")
                                docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                                    image.push()
                                    image.push("latest")
                                }
                            }
                        }
                    }
                }
                
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}")
                                docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                                    image.push()
                                    image.push("latest")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Update Manifests') {
            steps {
                sh '''
                    # Actualizar manifiestos con el username correcto
                    sed -i "s/your-dockerhub-username/${DOCKER_REGISTRY}/g" infra/k8s/staging/auth-api-deployment.yaml
                    sed -i "s/your-dockerhub-username/${DOCKER_REGISTRY}/g" infra/k8s/staging/users-api-deployment.yaml
                    sed -i "s/your-dockerhub-username/${DOCKER_REGISTRY}/g" infra/k8s/staging/todos-api-deployment.yaml
                    sed -i "s/your-dockerhub-username/${DOCKER_REGISTRY}/g" infra/k8s/staging/log-processor-deployment.yaml
                    sed -i "s/your-dockerhub-username/${DOCKER_REGISTRY}/g" infra/k8s/staging/frontend-deployment.yaml
                '''
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    kubectl apply -f infra/k8s/staging/namespace.yaml
                    kubectl apply -f infra/k8s/staging/secrets.yaml
                    kubectl apply -f infra/k8s/staging/redis-queue-deployment.yaml
                    kubectl apply -f infra/k8s/staging/redis-queue-service.yaml
                    kubectl apply -f infra/k8s/staging/redis-cache-deployment.yaml
                    kubectl apply -f infra/k8s/staging/redis-cache-service.yaml
                    kubectl apply -f infra/k8s/staging/auth-api-deployment.yaml
                    kubectl apply -f infra/k8s/staging/auth-api-service.yaml
                    kubectl apply -f infra/k8s/staging/users-api-deployment.yaml
                    kubectl apply -f infra/k8s/staging/users-api-service.yaml
                    kubectl apply -f infra/k8s/staging/todos-api-deployment.yaml
                    kubectl apply -f infra/k8s/staging/todos-api-service.yaml
                    kubectl apply -f infra/k8s/staging/log-processor-deployment.yaml
                    kubectl apply -f infra/k8s/staging/frontend-deployment.yaml
                    kubectl apply -f infra/k8s/staging/frontend-service.yaml
                    kubectl apply -f infra/k8s/staging/hpa-todos-api.yaml
                    kubectl apply -f infra/k8s/staging/keda-scaler.yaml
                    kubectl apply -f infra/k8s/staging/ingress.yaml
                '''
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get pods -n microservices-staging
                    kubectl get services -n microservices-staging
                    kubectl get ingress -n microservices-staging
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f || true'  # Agregar || true para evitar fallo
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}