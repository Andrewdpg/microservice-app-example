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
            rm -rf infra/k8s/_render && mkdir -p infra/k8s/_render
            cp infra/k8s/namespaces.yaml infra/k8s/_render/
            find infra/k8s -type f -name "*.yaml" ! -path "*/_render/*" ! -name "kustomization.yaml" | while read f; do
              name=$(basename "$f")
              sed -e "s|\\${REGISTRY}|${REGISTRY}|g" -e "s|\\${IMAGE_TAG}|${IMAGE_TAG}|g" "$f" > "infra/k8s/_render/$name"
            done
            echo "Rendered files:"; ls -la infra/k8s/_render

            # Usa el kubeconfig de la credencial (variable $KCFG)
            kubectl --kubeconfig "$KCFG" apply -f infra/k8s/namespaces.yaml --validate=false
            kubectl --kubeconfig "$KCFG" apply -f infra/k8s/_render -R --validate=false
          '''
        }
      }
    }
  }

}


