pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'cloning repo'
                git branch: 'main', url: 'https://github.com/Nagasai31-rgb/ansible-task.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    dir("${WORKSPACE}") {
                        sh 'terraform init'
                        sh 'terraform validate'

                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                            sh 'terraform plan'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }

        /* ---------------------------------------------------------
           NEW UPDATED ANSIBLE DEPLOYMENT STAGE
        --------------------------------------------------------- */
        stage('Ansible Deployment') {
            steps {
                script {

                    // Ensure key permissions for SSH
                    sh 'chmod 400 my-key.pem'

                    // -----------------------------
                    // AMAZON LINUX (frontend)
                    // -----------------------------
                    ansiblePlaybook(
                        credentialsId: '',                   // no Jenkins creds
                        inventory: 'inventory.yaml',
                        playbook: 'amazon-playbook.yml',
                        disableHostKeyChecking: true,
                        extras: "-u ec2-user --private-key my-key.pem"
                    )

                    // -----------------------------
                    // UBUNTU (backend)
                    // -----------------------------
                    ansiblePlaybook(
                        credentialsId: '',
                        inventory: 'inventory.yaml',
                        playbook: 'ubuntu-playbook.yml',
                        disableHostKeyChecking: true,
                        extras: "-u ubuntu --private-key my-key.pem"
                    )
                }
            }
        }
    }
}
