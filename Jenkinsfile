pipeline {
    agent any

    stages {

        /* ---------------------------------------------------------
           CHECKOUT CODE
        --------------------------------------------------------- */
        stage('Checkout') {
            steps {
                echo 'Cloning repo...'
                git branch: 'main', url: 'https://github.com/Nagasai31-rgb/ansible-task.git'
            }
        }

        /* ---------------------------------------------------------
           TERRAFORM APPLY
        --------------------------------------------------------- */
        stage('Terraform Apply') {
            steps {
                script {
                    dir("${WORKSPACE}") {

                        sh "terraform init"
                        sh "terraform validate"

                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                          credentialsId: 'aws-creds']]) {
                            sh "terraform plan"
                            sh "terraform apply -auto-approve"
                        }

                        // Wait for ansible-key.pem
                        sh '''
                        echo "Checking for ansible-key.pem..."

                        for i in {1..10}; do
                          if [ -f ansible-key.pem ]; then
                            echo "SSH key found: ansible-key.pem"
                            break
                          fi
                          echo "Key not created yet, retrying..."
                          sleep 2
                        done

                        if [ ! -f ansible-key.pem ]; then
                          echo "ERROR: ansible-key.pem NOT found!"
                          exit 1
                        fi

                        chmod 400 ansible-key.pem
                        '''
                    }
                }
            }
        }

        /* ---------------------------------------------------------
           ANSIBLE DEPLOYMENT
        --------------------------------------------------------- */
        stage('Ansible Deployment') {
            steps {
                script {

                    if (!fileExists("inventory.yaml")) {
                        error "inventory.yaml NOT found! Terraform must generate it."
                    }

                    echo "========= Running Ansible on Amazon Linux Frontend ========="
                    ansiblePlaybook(
                        playbook: "amazon-playbook.yml",
                        inventory: "inventory.yaml",
                        disableHostKeyChecking: true,
                        extras: "-u ec2-user --private-key ${WORKSPACE}/ansible-key.pem"
                    )

                    echo "========= Running Ansible on Ubuntu Backend ========="
                    ansiblePlaybook(
                        playbook: "ubuntu-playbook.yml",
                        inventory: "inventory.yaml",
                        disableHostKeyChecking: true,
                        extras: "-u ubuntu --private-key ${WORKSPACE}/ansible-key.pem"
                    )
                }
            }
        }
    }
}
