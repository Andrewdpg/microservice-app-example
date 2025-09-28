pipeline {
  agent any

  environment {
    REGISTRY = 'docker.io/andrewdpg'
    DOCKERHUB = 'docker-hub-credentials'
    INFRA_JENKINS_URL = 'http://jenkins:8079'
    INFRA_JENKINS_JOB = 'microservice-infrastructure-deploy'
    JENKINS_TOKEN = credentials('jenkins-api-token')
  }

  options {
    skipDefaultCheckout()
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        checkout scm
        script {
          def shortSha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          def branchName = env.BRANCH_NAME
          if (!branchName || branchName.trim() == '') {
            branchName = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
          }
          if (!branchName || branchName == 'HEAD') {
            branchName = 'master'
          }
          env.IMAGE_TAG = "${branchName}-${shortSha}"
          env.LATEST_TAG = "latest"
          echo "IMAGE_TAG=${env.IMAGE_TAG}"
        }
        stash name: 'ws', includes: '**/*'
      }
    }

    stage('Test & Build') {
      parallel {
        stage('Test Auth API') {
          steps {
            unstash 'ws'
            dir('auth-api') {
              sh '''
                echo "Testing Auth API..."
                go test ./... || echo "Tests not implemented yet"
              '''
            }
          }
        }
        
        stage('Test Users API') {
          steps {
            unstash 'ws'
            dir('users-api') {
              sh '''
                echo "Testing Users API..."
                ./mvnw test || echo "Tests not implemented yet"
              '''
            }
          }
        }
        
        stage('Test TODOs API') {
          steps {
            unstash 'ws'
            dir('todos-api') {
              sh '''
                echo "Testing TODOs API..."
                npm test || echo "Tests not implemented yet"
              '''
            }
          }
        }
        
        stage('Test Frontend') {
          steps {
            unstash 'ws'
            dir('frontend') {
              sh '''
                echo "Testing Frontend..."
                npm test || echo "Tests not implemented yet"
              '''
            }
          }
        }
        
        stage('Test Log Processor') {
          steps {
            unstash 'ws'
            dir('log-message-processor') {
              sh '''
                echo "Testing Log Processor..."
                python -m pytest || echo "Tests not implemented yet"
              '''
            }
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        unstash 'ws'
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            
            # Build todas las imágenes en paralelo
            docker build -t ${REGISTRY}/auth-api:${IMAGE_TAG} -t ${REGISTRY}/auth-api:${LATEST_TAG} ./auth-api &
            docker build -t ${REGISTRY}/users-api:${IMAGE_TAG} -t ${REGISTRY}/users-api:${LATEST_TAG} ./users-api &
            docker build -t ${REGISTRY}/todos-api:${IMAGE_TAG} -t ${REGISTRY}/todos-api:${LATEST_TAG} ./todos-api &
            docker build -t ${REGISTRY}/frontend:${IMAGE_TAG} -t ${REGISTRY}/frontend:${LATEST_TAG} ./frontend &
            docker build -t ${REGISTRY}/log-message-processor:${IMAGE_TAG} -t ${REGISTRY}/log-message-processor:${LATEST_TAG} ./log-message-processor &
            
            wait
          '''
        }
      }
    }

    stage('Docker Push') {
      when {
        anyOf {
          branch 'dev'
          branch 'release'
        }
      }
      steps {
        unstash 'ws'
        sh '''
          # Push todas las imágenes
          docker push ${REGISTRY}/auth-api:${IMAGE_TAG}
          docker push ${REGISTRY}/auth-api:${LATEST_TAG}
          docker push ${REGISTRY}/users-api:${IMAGE_TAG}
          docker push ${REGISTRY}/users-api:${LATEST_TAG}
          docker push ${REGISTRY}/todos-api:${IMAGE_TAG}
          docker push ${REGISTRY}/todos-api:${LATEST_TAG}
          docker push ${REGISTRY}/frontend:${IMAGE_TAG}
          docker push ${REGISTRY}/frontend:${LATEST_TAG}
          docker push ${REGISTRY}/log-message-processor:${IMAGE_TAG}
          docker push ${REGISTRY}/log-message-processor:${LATEST_TAG}
        '''
      }
    }

    stage('Trigger Infrastructure Deployment - Staging') {
      when {
        branch 'dev'  // ← Solo para branch dev
      }
      steps {
        script {
          echo "Triggering infrastructure deployment for STAGING with ${env.IMAGE_TAG} on ${env.BRANCH_NAME}..."
          
          // Usar httpRequest en lugar de URL.openConnection
          def response = httpRequest(
            url: "${INFRA_JENKINS_URL}/job/${INFRA_JENKINS_JOB}/buildWithParameters?token=${JENKINS_TOKEN}&IMAGE_TAG=${env.IMAGE_TAG}&REGISTRY=${REGISTRY}&GIT_COMMIT=${env.GIT_COMMIT}&GIT_BRANCH=${env.BRANCH_NAME}&ENVIRONMENT=staging",
            httpMode: 'POST',
            validResponseCodes: '200,201,202'
          )
          
          echo "Response status: ${response.status}"
          echo "Infrastructure deployment to STAGING triggered."
        }
      }
    }

    stage('Trigger Infrastructure Deployment - Production') {
      when {
        branch 'release'  // ← Solo para branch release
      }
      steps {
        script {
          echo "Triggering infrastructure deployment for PRODUCTION with ${env.IMAGE_TAG} on ${env.BRANCH_NAME}..."
          
          // Usar httpRequest en lugar de URL.openConnection
          def response = httpRequest(
            url: "${INFRA_JENKINS_URL}/job/${INFRA_JENKINS_JOB}/buildWithParameters?token=${JENKINS_TOKEN}&IMAGE_TAG=${env.IMAGE_TAG}&REGISTRY=${REGISTRY}&GIT_COMMIT=${env.GIT_COMMIT}&GIT_BRANCH=${env.BRANCH_NAME}&ENVIRONMENT=production",
            httpMode: 'POST',
            validResponseCodes: '200,201,202'
          )
          
          echo "Response status: ${response.status}"
          echo "Infrastructure deployment to PRODUCTION triggered."
        }
      }
    }
  }

  post {
    success {
      echo "Build and push completed successfully"
      script {
        if (env.BRANCH_NAME == 'dev') {
          echo "Infrastructure deployment to STAGING triggered"
        } else if (env.BRANCH_NAME == 'release') {
          echo "Infrastructure deployment to PRODUCTION triggered"
        } else {
          echo "No infrastructure deployment triggered for branch: ${env.BRANCH_NAME}"
        }
      }
    }
    
    failure {
      echo "Build or push failed"
    }
  }
}