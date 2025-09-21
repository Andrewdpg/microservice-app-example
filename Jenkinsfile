pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'andrewdpg'  // Cambiar por tu usuario de Docker Hub
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBECONFIG = '/var/jenkins_home/.kube/config'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build and Test') {
            parallel {
                stage('Auth API') {
                    steps {
                        dir('auth-api') {
                            sh 'docker build -t ${DOCKER_REGISTRY}/auth-api:${IMAGE_TAG} .'
                            sh 'docker build -t ${DOCKER_REGISTRY}/auth-api:latest .'
                        }
                    }
                }
                
                stage('Users API') {
                    steps {
                        dir('users-api') {
                            sh 'docker build -t ${DOCKER_REGISTRY}/users-api:${IMAGE_TAG} .'
                            sh 'docker build -t ${DOCKER_REGISTRY}/users-api:latest .'
                        }
                    }
                }
                
                stage('TODOs API') {
                    steps {
                        dir('todos-api') {
                            sh 'docker build -t ${DOCKER_REGISTRY}/todos-api:${IMAGE_TAG} .'
                            sh 'docker build -t ${DOCKER_REGISTRY}/todos-api:latest .'
                        }
                    }
                }
                
                stage('Log Processor') {
                    steps {
                        dir('log-message-processor') {
                            sh 'docker build -t ${DOCKER_REGISTRY}/log-processor:${IMAGE_TAG} .'
                            sh 'docker build -t ${DOCKER_REGISTRY}/log-processor:latest .'
                        }
                    }
                }
                
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'docker build -t ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG} .'
                            sh 'docker build -t ${DOCKER_REGISTRY}/frontend:latest .'
                        }
                    }
                }
            }
        }
        
        stage('Push Images') {
            steps {
                script {
                    def images = [
                        'auth-api',
                        'users-api', 
                        'todos-api',
                        'log-processor',
                        'frontend'
                    ]
                    
                    images.each { image ->
                        sh "docker push ${DOCKER_REGISTRY}/${image}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_REGISTRY}/${image}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                sh 'kubectl apply -f infra/k8s/staging/'
                sh 'kubectl rollout status deployment/auth-api -n microservices-staging'
                sh 'kubectl rollout status deployment/users-api -n microservices-staging'
                sh 'kubectl rollout status deployment/todos-api -n microservices-staging'
                sh 'kubectl rollout status deployment/log-processor -n microservices-staging'
                sh 'kubectl rollout status deployment/frontend -n microservices-staging'
            }
        }
        
        stage('Deploy to Production') {
            when {
                tag pattern: "v\\d+\\.\\d+\\.\\d+", comparator: "REGEXP"
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                sh 'kubectl apply -f infra/k8s/prod/'
                sh 'kubectl rollout status deployment/auth-api -n microservices-prod'
                sh 'kubectl rollout status deployment/users-api -n microservices-prod'
                sh 'kubectl rollout status deployment/todos-api -n microservices-prod'
                sh 'kubectl rollout status deployment/log-processor -n microservices-prod'
                sh 'kubectl rollout status deployment/frontend -n microservices-prod'
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}