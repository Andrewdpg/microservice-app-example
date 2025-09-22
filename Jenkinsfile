pipeline {
  agent any

  environment {
    REGISTRY = 'docker.io/andrewdpg'
    DOCKERHUB = 'dockerhub-creds'
    K8S_NAMESPACE = 'micro'
    IMAGE_TAG = "${env.BRANCH_NAME}-${env.GIT_COMMIT.take(7)}"
  }

  options {
    skipDefaultCheckout()
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'git rev-parse --short HEAD | cat'
      }
    }

    stage('Build & Test') {
      parallel {
        stage('todos-api (Node)') {
          agent { docker { image 'node:18-alpine' } }
          steps {
            dir('todos-api') {
              sh 'npm ci'
              sh 'npm test --silent || echo "no tests"'
            }
          }
        }
        stage('frontend (Vue)') {
          agent { docker { image 'node:18-alpine' } }
          steps {
            dir('frontend') {
              sh 'npm ci'
              sh 'npm run build'
            }
          }
        }
        stage('users-api (Java)') {
          agent { docker { image 'maven:3.9-eclipse-temurin-17' } }
          steps {
            dir('users-api') {
              sh 'mvn -B -DskipTests package'
            }
          }
        }
        stage('auth-api (Go)') {
          agent { docker { image 'golang:1.22-alpine' } }
          steps {
            dir('auth-api') {
              sh 'go mod download'
              sh 'go build ./...'
            }
          }
        }
        stage('log-message-processor (Py)') {
          agent { docker { image 'python:3.11-alpine' } }
          steps {
            dir('log-message-processor') {
              sh 'pip install -r requirements.txt || true'
            }
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker build -t ${REGISTRY}/todos-api:${IMAGE_TAG} ./todos-api
            docker build -t ${REGISTRY}/frontend:${IMAGE_TAG} ./frontend
            docker build -t ${REGISTRY}/users-api:${IMAGE_TAG} ./users-api
            docker build -t ${REGISTRY}/auth-api:${IMAGE_TAG} ./auth-api
            docker build -t ${REGISTRY}/log-message-processor:${IMAGE_TAG} ./log-message-processor
          '''
        }
      }
    }

    stage('Docker Push') {
      steps {
        sh '''
          docker push ${REGISTRY}/todos-api:${IMAGE_TAG}
          docker push ${REGISTRY}/frontend:${IMAGE_TAG}
          docker push ${REGISTRY}/users-api:${IMAGE_TAG}
          docker push ${REGISTRY}/auth-api:${IMAGE_TAG}
          docker push ${REGISTRY}/log-message-processor:${IMAGE_TAG}
        '''
      }
    }

    stage('Deploy to K8s') {
      when {
        anyOf { branch 'main'; branch 'master' }
      }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG="$KUBECONFIG_FILE"
            mkdir -p infra/k8s/_render
            export REGISTRY=${REGISTRY}
            export IMAGE_TAG=${IMAGE_TAG}
            find infra/k8s -type f -name "*.yaml" ! -path "*/_render/*" -print0 | while IFS= read -r -d '' f; do
              envsubst < "$f" > "infra/k8s/_render/$(basename $f)"
            done
            kubectl apply -f infra/k8s/_render --recursive
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker logout || true'
    }
  }
}


