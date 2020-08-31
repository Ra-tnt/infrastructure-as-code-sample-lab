pipeline {
  agent {
    docker {
      image "bryandollery/terraform-packer-aws-alpine"
      args "-u root --entrypoint=''"
    }
  }
  environment {
    CREDS = credentials('Raghadq-cred')
    AWS_ACCESS_KEY_ID = "${CREDS_USR}"
    AWS_SECRET_ACCESS_KEY = "${CREDS_PSW}"
    OWNER = "theta"
    PROJECT_NAME = 'web-server'
    AWS_PROFILE="kh-labs"
    TF_NAMESPACE="raghadq"
  }
  stages {
      stage("init") {
          steps {
              sh 'make init'
          }
      }
      stage("workspace") {
          steps {
              sh """
terraform workspace select Raghadq-tf
if [[ \$? -ne 0 ]]; then
  terraform workspace new Raghadq-tf
fi
"""
          }
      }
      stage("plan") {
          steps {
              sh 'make init'
              sh 'make plan'
          }
  }}}
