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
          args '--entrypoint="" --network kind -u 0:0'
        }
      }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KCFG')]) {
          sh '''
            set -e
            export REGISTRY="${REGISTRY}"
            export IMAGE_TAG="${IMAGE_TAG}"

            rm -rf infra/k8s/_render && mkdir -p infra/k8s/_render
            cp infra/k8s/namespaces.yaml infra/k8s/_render/

            # Renderiza todos los YAMLs preservando rutas; excluye kustomization y RBAC
            find infra/k8s -type f -name "*.yaml" \
              ! -path "*/_render/*" \
              ! -name "kustomization.yaml" \
              ! -name "rbac-jenkins.yaml" \
              -print | while read -r f; do
                out="infra/k8s/_render/${f#infra/k8s/}"
                mkdir -p "$(dirname "$out")"
                sed -e "s|\\${REGISTRY}|${REGISTRY}|g" \
                    -e "s|\\${IMAGE_TAG}|${IMAGE_TAG}|g" "$f" > "$out"
            done

            echo "Rendered files:"; find infra/k8s/_render -type f -maxdepth 3 -print
            kubectl --kubeconfig "$KCFG" apply -f infra/k8s/namespaces.yaml --validate=false
            kubectl --kubeconfig "$KCFG" apply -f infra/k8s/_render -R --validate=false
          '''
        }
      }
    }
  }

}


