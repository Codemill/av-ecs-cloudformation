#!/usr/bin/env bash

read -rp "AWS Region (required): " REGION
read -rp "AWS Profile [default]: " PROFILE
read -rp "Infrastructure stack name [av-ecs]: " INFRASTRUCTURE_STACK_NAME
read -rp "Cluster name [av-cluster]: " CLUSTER_NAME
read -rp "Image registry credentials (required): " REGISTRY_CREDENTIALS
read -rp "Database name [accurateVideo]: " DATABASE_NAME
read -rp "Database user [postgres]: " DATABASE_USER
read -rp "Database class [db.t3.small]: " DATABASE_CLASS
read -rp "Database size in GB [5]: " DATABASE_ALLOCATED_STORAGE

PROFILE=${PROFILE:-default}
INFRASTRUCTURE_STACK_NAME=${INFRASTRUCTURE_STACK_NAME:-av-ecs}
CLUSTER_NAME=${CLUSTER_NAME:-av-cluster}
DATABASE_NAME=${DATABASE_NAME:-accurateVideo}
DATABASE_USER=${DATABASE_USER:-postgres}
DATABASE_CLASS=${DATABASE_CLASS:-db.t3.small}
DATABASE_ALLOCATED_STORAGE=${DATABASE_ALLOCATED_STORAGE:-5}

ADAPTER_IMAGE_TAG="4.2.1"
ANALYZE_IMAGE_TAG="1.2.1"
FRONTEND_IMAGE_TAG="v4.2.2-rc.0"
JOBS_IMAGE_TAG="4.2.1"

ADAPTER_CONTAINER_CPU="256"
ANALYZE_CONTAINER_CPU="256"
FRONTEND_CONTAINER_CPU="256"
JOBS_CONTAINER_CPU="512"

ADAPTER_CONTAINER_MEMORY="1024"
ANALYZE_CONTAINER_MEMORY="512"
FRONTEND_CONTAINER_MEMORY="512"
JOBS_CONTAINER_MEMORY="1024"

ADAPTER_CONTAINER_DESIRED_COUNT="2"
ANALYZE_CONTAINER_DESIRED_COUNT="2"
FRONTEND_CONTAINER_DESIRED_COUNT="2"
JOBS_CONTAINER_DESIRED_COUNT="2"


if [ -z "${REGION}" ]; then
  printf "ERR: Missing region\n" >&2
  exit 1
fi

if [ -z "${REGISTRY_CREDENTIALS}" ]; then
  printf "ERR: Missing registry credentials\n" >&2
  exit 1
fi

printf "Creating Infrastructure stack...\n"
echo aws cloudformation create-stack \
  --template-body file://./infrastructure.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}" \
  --parameters \
    ParameterKey=ClusterName,ParameterValue="${CLUSTER_NAME}" \
    ParameterKey=DBName,ParameterValue="${DATABASE_NAME}" \
    ParameterKey=DBUser,ParameterValue="${DATABASE_USER}" \
    ParameterKey=DBClass,ParameterValue="${DATABASE_CLASS}" \
    ParameterKey=DBAllocatedStorage,ParameterValue="${DATABASE_ALLOCATED_STORAGE}" \
  --capabilities CAPABILITY_IAM \
  --region "${REGION}" \
  --profile "${PROFILE}"

printf "Waiting for Infrastructure to complete...\n"
aws cloudformation wait stack-create-complete \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}" \
    --region "${REGION}" \
    --profile "${PROFILE}"

INFRASTRUCTURE_CREATE_CODE=$?
if [ "${INFRASTRUCTURE_CREATE_CODE}" != 0 ]; then
  printf "ERR: Failed waiting for stack %s to complete: %s\n" "${INFRASTRUCTURE_STACK_NAME}" "${INFRASTRUCTURE_CREATE_CODE}" >&2
  exit 1
fi

CONFIG_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}" \
    --query "Stacks[0].Outputs[?OutputKey=='ConfigBucketName'].OutputValue" \
    --output text \
    --region "${REGION}" \
    --profile "${PROFILE}")

printf "Creating %s stack...\n" "${INFRASTRUCTURE_STACK_NAME}-adapter"
aws cloudformation create-stack \
  --template-body file://./av-adapter-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-adapter" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=DBName,ParameterValue="${DATABASE_NAME}" \
    ParameterKey=ImageTag,ParameterValue="${ADAPTER_IMAGE_TAG}" \
    ParameterKey=ContainerCpu,ParameterValue="${ADAPTER_CONTAINER_CPU}" \
    ParameterKey=ContainerMemory,ParameterValue="${ADAPTER_CONTAINER_MEMORY}" \
    ParameterKey=DesiredCount,ParameterValue="${ADAPTER_DESIRED_COUNT}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}" \
  --capabilities CAPABILITY_IAM \
  --region "${REGION}" \
  --profile "${PROFILE}"
printf "Creating %s stack...\n" "${INFRASTRUCTURE_STACK_NAME}-frontend"
aws cloudformation create-stack \
  --template-body file://./av-frontend-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-frontend" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=ImageTag,ParameterValue="${FRONTEND_IMAGE_TAG}" \
    ParameterKey=ContainerCpu,ParameterValue="${FRONTEND_CONTAINER_CPU}" \
    ParameterKey=ContainerMemory,ParameterValue="${FRONTEND_CONTAINER_MEMORY}" \
    ParameterKey=DesiredCount,ParameterValue="${FRONTEND_DESIRED_COUNT}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}" \
  --capabilities CAPABILITY_IAM \
  --region "${REGION}" \
  --profile "${PROFILE}"

printf "Creating %s stack...\n" "${INFRASTRUCTURE_STACK_NAME}-analyze"
aws cloudformation create-stack \
  --template-body file://./av-analyze-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-analyze" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=ImageTag,ParameterValue="${ANALYZE_IMAGE_TAG}" \
    ParameterKey=ContainerCpu,ParameterValue="${ANALYZE_CONTAINER_CPU}" \
    ParameterKey=ContainerMemory,ParameterValue="${ANALYZE_CONTAINER_MEMORY}" \
    ParameterKey=DesiredCount,ParameterValue="${ANALYZE_DESIRED_COUNT}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}" \
  --capabilities CAPABILITY_IAM \
  --region "${REGION}" \
  --profile "${PROFILE}"

printf "Waiting for %s to complete...\n" "${INFRASTRUCTURE_STACK_NAME}-adapter"
aws cloudformation wait stack-create-complete \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}-adapter" \
    --region "${REGION}" \
    --profile "${PROFILE}"

ADAPTER_CREATE_CODE=$?
if [ "${ADAPTER_CREATE_CODE}" != "0" ]; then
  printf "ERR: Failed waiting for stack %s to complete: %s\n" "${INFRASTRUCTURE_STACK_NAME}" "${ADAPTER_CREATE_CODE}" >&2
  exit 1
fi

printf "Creating %s stack...\n" "${INFRASTRUCTURE_STACK_NAME}-jobs"
aws cloudformation create-stack \
  --template-body file://./av-jobs-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-jobs" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=AdapterStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}-adapter" \
    ParameterKey=ImageTag,ParameterValue="${JOBS_IMAGE_TAG}" \
    ParameterKey=ContainerCpu,ParameterValue="${JOBS_CONTAINER_CPU}" \
    ParameterKey=ContainerMemory,ParameterValue="${JOBS_CONTAINER_MEMORY}" \
    ParameterKey=DesiredCount,ParameterValue="${JOBS_DESIRED_COUNT}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}" \
  --capabilities CAPABILITY_IAM \
  --region "${REGION}" \
  --profile "${PROFILE}"

printf "Waiting for %s to complete...\n" "${INFRASTRUCTURE_STACK_NAME}-jobs"
aws cloudformation wait stack-create-complete \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}-jobs" \
    --region "${REGION}" \
    --profile "${PROFILE}"

printf "Done!\n"
