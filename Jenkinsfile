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

                        // -------------------------------------------------------
                        // Wait for Terraform-generated SSH key (my-key.pem)
                        // -------------------------------------------------------
                        sh '''
                        echo "Checking for Terraform-generated SSH key..."

                        for i in {1..10}; do
                          if [ -f my-key.pem ]; then
                            echo "SSH key found: my-key.pem"
                            break
                          fi
                          echo "Key not created yet, retrying..."
                          sleep 2
                        done

                        if [ ! -f my-key.pem ]; then
                          echo "ERROR: my-key.pem NOT found!"
                          exit 1
                        fi

                        chmod 400 my-key.pem
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

                    // Make sure inventory file exists
                    if (!fileExists("inventory.yaml")) {
                        error "inventory.yaml not found! Terraform must generate it."
                    }

                    echo "========= Running Ansible on Frontend (Amazon Linux) ========="
                    ansiblePlaybook(
                        playbook: "amazon-playbook.yml",
                        inventory: "inventory.yaml",
                        disableHostKeyChecking: true,
                        extras: "-u ec2-user --private-key ${WORKSPACE}/my-key.pem"
                    )

                    echo "========= Running Ansible on Backend (Ubuntu) ========="
                    ansiblePlaybook(
                        playbook: "ubuntu-playbook.yml",
                        inventory: "inventory.yaml",
                        disableHostKeyChecking: true,
                        extras: "-u ubuntu --private-key ${WORKSPACE}/my-key.pem"
                    )
                }
            }
        }
    }
}
