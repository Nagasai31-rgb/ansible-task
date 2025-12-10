pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning repo...'
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

                        // -------------------------------
                        // Wait until Terraform creates key
                        // -------------------------------
                        sh '''
                        echo "Waiting for Terraform-generated key..."
                        for i in {1..10}; do
                          if [ -f my-key.pem ]; then
                            echo "Key found!"
                            break
                          fi
                          echo "Key not found, retrying..."
                          sleep 2
                        done

                        if [ ! -f my-key.pem ]; then
                          echo "ERROR: my-key.pem not created by Terraform!"
                          exit 1
                        fi
                        '''
                    }
                }
            }
        }

        // ---------------------------------------------------------
        // ANSIBLE DEPLOYMENT
        // ---------------------------------------------------------
        stage('Ansible Deployment') {
            steps {
                script {

                    // Ensure correct permissions for SSH key
                    sh 'chmod 400 my-key.pem'

                    echo "Running Ansible on Frontend EC2 (Amazon Linux)..."
                    ansiblePlaybook(
                        credentialsId: '', 
                        inventory: 'inventory.yaml',
                        playbook: 'amazon-playbook.yml',
                        disableHostKeyChecking: true,
                        extras: "-u ec2-user --private-key my-key.pem"
                    )

                    echo "Running Ansible on Backend EC2 (Ubuntu)..."
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
