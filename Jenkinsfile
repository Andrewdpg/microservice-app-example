pipeline {
  agent any

  environment {
    REGISTRY = 'docker.io/andrewdpg'
    DOCKERHUB = 'docker-hub-credentials'
    K8S_NAMESPACE = 'micro'
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
          echo "IMAGE_TAG=${env.IMAGE_TAG}"
        }
        stash name: 'ws', includes: '**/*'
      }
    }

    stage('Build & Test') {
      parallel {
        stage('todos-api (Node)') {
          agent { docker { image 'node:18-alpine' } }
          steps {
            unstash 'ws'
            dir('todos-api') {
              sh 'npm ci'
              sh 'npm test --silent || echo "no tests"'
            }
          }
        }
        stage('frontend (Vue)') {
          agent { docker { image 'node:8.17.0-alpine' } }
          steps {
            unstash 'ws'
            dir('frontend') {
              sh 'node -v && npm -v'
              sh 'npm ci'
              sh 'npm run build'
            }
          }
        }
        stage('users-api (Java)') {
          agent { docker { image 'maven:3.9-eclipse-temurin-17' } }
          steps {
            unstash 'ws'
            dir('users-api') {
              sh 'mvn -B -DskipTests package'
            }
          }
        }
        stage('auth-api (Go)') {
          agent { docker { image 'golang:1.22-alpine' } }
          steps {
            unstash 'ws'
            dir('auth-api') {
              sh 'go mod download'
              sh 'go build ./...'
            }
          }
        }
        stage('log-message-processor (Py)') {
          agent { docker { image 'python:3.11-alpine' } }
          steps {
            unstash 'ws'
            dir('log-message-processor') {
              sh 'pip install -r requirements.txt || true'
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
        unstash 'ws'
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
      agent {
        docker {
          image 'bitnami/kubectl:1.29'
          args '-u 0:0 --entrypoint=""' // sin --network
        }
      }
      steps {
        withCredentials([file(credentialsId: 'jenkins-kubeconfig', variable: 'KCFG')]) {
          sh '''
            set -e
            # 1) Descubre el puerto del API de kind en el host
            HOSTPORT=$(docker inspect ci-control-plane --format '{{(index (index .NetworkSettings.Ports "6443/tcp") 0).HostPort}}')

            # 2) Genera kubeconfig temporal con server en host.docker.internal:HOSTPORT
            cp jenkins-kubeconfig.yaml k.tmp.yaml
            sed -i "s#^\\s*server: .*#    server: https://host.docker.internal:${HOSTPORT}#g" k.tmp.yaml

            # 3) Aplica primero namespaces y luego todo lo renderizado (evita validar OpenAPI para no depender de conectividad extra)
            mkdir -p infra/k8s/_render
            cp infra/k8s/namespaces.yaml infra/k8s/_render/
            find infra/k8s -type f -name "*.yaml" ! -path "*/_render/*" ! -name "kustomization.yaml" | while read f; do
              name=$(basename "$f")
              sed -e "s|\\${REGISTRY}|${REGISTRY}|g" -e "s|\\${IMAGE_TAG}|${IMAGE_TAG}|g" "$f" > "infra/k8s/_render/$name"
            done

            echo "Rendered files:"; ls -la infra/k8s/_render

            kubectl --kubeconfig k.tmp.yaml apply -f infra/k8s/namespaces.yaml --validate=false
            kubectl --kubeconfig k.tmp.yaml apply -f infra/k8s/_render -R --validate=false
          '''
        }
      }
    }
  }

}


