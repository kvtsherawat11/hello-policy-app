pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 45, unit: 'MINUTES')
    }

    triggers {
        githubPush()
    }

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '123456789012'

        ECR_REPOSITORY = 'hello-policy-app'
        ECS_CLUSTER = 'hello-policy-cluster'
        ECS_SERVICE = 'hello-policy-service'
        ECS_TASK_FAMILY = 'hello-policy-app'

        ECS_EXECUTION_ROLE_ARN = 'arn:aws:iam::123456789012:role/ecsTaskExecutionRole'

        SONARQUBE_INSTALLATION = 'SonarQube'
        SONAR_SCANNER_TOOL = 'sonar-scanner'

        APP_NAME = 'hello-policy-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHORT_COMMIT = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    env.IMAGE_URI = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_SHORT_COMMIT}"
                }
                sh '''
                    echo "Commit: ${GIT_SHORT_COMMIT}"
                    echo "Image:  ${IMAGE_URI}"
                '''
            }
        }

        stage('Validate Required Tools') {
            steps {
                sh '''
                    set -e
                    git --version
                    python3 --version
                    docker --version
                    aws --version
                    jq --version
                    conftest --version
                    trivy --version
                    aws sts get-caller-identity
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -e
                    rm -rf .venv
                    python3 -m venv .venv
                    . .venv/bin/activate
                    python -m pip install --upgrade pip
                    pip install --requirement requirements.txt
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    set -e
                    . .venv/bin/activate
                    pytest \
                      --junitxml=test-results.xml \
                      --cov=app \
                      --cov-report=term \
                      --cov-report=xml:coverage.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'test-results.xml'
                    archiveArtifacts artifacts: 'coverage.xml', allowEmptyArchive: true
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool SONAR_SCANNER_TOOL
                    withSonarQubeEnv(SONARQUBE_INSTALLATION) {
                        withCredentials([string(credentialsId: 'mysonarqube', variable: 'SONAR_TOKEN')]) {
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=${APP_NAME} \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=http://ec2-35-88-116-127.us-west-2.compute.amazonaws.com:9000 \
                                -Dsonar.login=$SONAR_TOKEN
                            """
                        }
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Policy Check - Dockerfile') {
            steps {
                sh '''
                    set -e
                    conftest test Dockerfile \
                      --policy policy/dockerfile.rego \
                      --parser dockerfile
                '''
            }
        }

        stage('Prepare ECS Task Definition') {
            steps {
                sh '''
                    set -e
                    jq \
                      --arg account "${AWS_ACCOUNT_ID}" \
                      --arg region "${AWS_REGION}" \
                      --arg role "${ECS_EXECUTION_ROLE_ARN}" \
                      --arg tag "${GIT_SHORT_COMMIT}" \
                      '
                        .executionRoleArn = $role
                        | .containerDefinitions[0].image =
                          ($account + ".dkr.ecr." + $region + ".amazonaws.com/hello-policy-app:" + $tag)
                        | .containerDefinitions[0].logConfiguration.options["awslogs-region"] = $region
                      ' ecs/task-definition.json > ecs/task-definition-rendered.json
                    cat ecs/task-definition-rendered.json
                '''
            }
        }

        stage('Policy Check - ECS Definition') {
            steps {
                sh '''
                    set -e
                    conftest test ecs/task-definition-rendered.json \
                      --policy policy/ecs.rego
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e
                    docker build --pull --tag "${IMAGE_URI}" .
                    docker image inspect "${IMAGE_URI}"
                '''
            }
        }

        stage('Container Smoke Test') {
            steps {
                sh '''
                    set -e
                    CONTAINER_ID="$(docker run --detach --publish 18080:8080 "${IMAGE_URI
