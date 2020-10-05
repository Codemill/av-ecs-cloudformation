#!/usr/bin/env bash

read -p 'AWS Region (required): ' REGION
read -p 'AWS Profile [default]: ' PROFILE
read -p 'Infrastructure stack name [av-ecs]: ' INFRASTRUCTURE_STACK_NAME
read -p 'Cluster name [av-cluster]: ' CLUSTER_NAME
read -p 'Image registry credentials (required): ' REGISTRY_CREDENTIALS
read -p 'Database name [accurateVideo]: ' DATABASE_NAME
read -p 'Database user [postgres]: ' DATABASE_USER
read -p 'Database class [db.t3.small]: ' DATABASE_CLASS
read -p 'Database size in GB [5]: ' DATABASE_ALLOCATED_STORAGE

PROFILE=${PROFILE:-default}
INFRASTRUCTURE_STACK_NAME=${INFRASTRUCTURE_STACK_NAME:-av-ecs}
CLUSTER_NAME=${CLUSTER_NAME:-av-cluster}
DATABASE_NAME=${DATABASE_NAME:-accurateVideo}
DATABASE_USER=${DATABASE_USER:-postgres}
DATABASE_CLASS=${DATABASE_CLASS:-db.t3.small}
DATABASE_ALLOCATED_STORAGE=${DATABASE_ALLOCATED_STORAGE:-5}

if [ -z "${REGION}" ]; then
  printf 'ERR: Missing region\n' >&2
  exit 1
fi

if [ -z "${REGISTRY_CREDENTIALS}" ]; then
  printf 'ERR: Missing registry credentials\n' >&2
  exit 1
fi

printf 'Creating Infrastructure stack...\n'
aws cloudformation create-stack \
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

printf 'Waiting for Infrastructure to complete...\n'
aws cloudformation wait stack-create-complete \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}" \
    --region "${REGION}" \
    --profile "${PROFILE}"

INFRASTRUCTURE_CREATE_CODE=$?
if [ INFRASTRUCTURE_CREATE_CODE != "0" ]; then
  printf 'ERR: Failed waiting for stack %s to complete: %s\n' "${INFRASTRUCTURE_STACK_NAME}" "${INFRASTRUCTURE_CREATE_CODE}" >&2
  exit 1
fi

CONFIG_BUCKET=aws cloudformation describe-stacks \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}" \
    --query "Stacks[0].Outputs[?OutputKey=='ConfigBucketName'].OutputValue" \
    --output text \
    --region "${REGION}" \
    --profile "${PROFILE}"

aws s3 cp --recursive ./config/frontend "s3://${CONFIG_BUCKET}/frontend" --profile "${PROFILE}"
aws s3 cp --recursive ./config/backend "s3://${CONFIG_BUCKET}/backend" --profile "${PROFILE}"

printf 'Creating ${INFRASTRUCTURE_STACK_NAME}-adapter stack...\n'
aws cloudformation create-stack \
  --template-body file://./av-adapter-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-adapter" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}" \
    ParameterKey=DBName,ParameterValue="${DATABASE_NAME}"

printf 'Creating ${INFRASTRUCTURE_STACK_NAME}-frontend stack...\n'
aws cloudformation create-stack \
  --template-body file://./av-frontend-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-frontend" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}" \

printf 'Creating ${INFRASTRUCTURE_STACK_NAME}-analyze stack...\n'
aws cloudformation create-stack \
  --template-body file://./av-analyze-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-analyze" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}"

printf 'Waiting for ${INFRASTRUCTURE_STACK_NAME}-adapter to complete...\n'
aws cloudformation wait stack-create-complete \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}-adapter" \
    --region "${REGION}" \
    --profile "${PROFILE}"

ADAPTER_CREATE_CODE=$?
if [ ADAPTER_CREATE_CODE != "0" ]; then
  printf 'ERR: Failed waiting for stack %s to complete: %s\n' "${INFRASTRUCTURE_STACK_NAME}" "${ADAPTER_CREATE_CODE}" >&2
  exit 1
fi

aws cloudformation create-stack \
  --template-body file://./av-jobs-deployment.yaml \
  --stack-name "${INFRASTRUCTURE_STACK_NAME}-jobs" \
  --parameters \
    ParameterKey=InfrastructureStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}" \
    ParameterKey=AdapterStackName,ParameterValue="${INFRASTRUCTURE_STACK_NAME}-adapter" \
    ParameterKey=RegistryCredentials,ParameterValue="${REGISTRY_CREDENTIALS}"
