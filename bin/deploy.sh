#!/usr/bin/env bash

set -o allexport
[[ -f .env ]] && source .env
set +o allexport

PROFILE="${1}"
REGION="${2}"
TEMPLATE_BUCKET_NAME="${3}"

if [ -z "${PROFILE}" ] ; then
  read -rp "AWS Profile: " PROFILE
fi

if [ -z "${REGION}" ] ; then
  read -rp "AWS Region: " REGION
fi

if [ -z "${TEMPLATE_BUCKET_NAME}" ] ; then
  read -rp "AWS S3 Bucket Name: " TEMPLATE_BUCKET_NAME
fi

aws cloudformation package \
  --template-file main.yaml \
  --output-template packaged.yaml \
  --s3-bucket "${TEMPLATE_BUCKET_NAME}" \
  --profile "${PROFILE}" \
  --region "${REGION}"

aws cloudformation deploy \
  --template-file ./packaged.yaml \
  --stack-name "${STACK_NAME}" \
  --parameter-overrides \
    AdapterContainerCpu="${ADAPTER_CONTAINER_CPU}" \
    AdapterContainerMemory="${ADAPTER_CONTAINER_MEMORY}" \
    AdapterDesiredCount="${ADAPTER_DESIRED_COUNT}" \
    AdapterImageTag="${ADAPTER_IMAGE_TAG}" \
    AdapterRdsDbClass="${ADAPTER_RDS_DB_CLASS}" \
    AnalyzeContainerCpu="${ANALYZE_CONTAINER_CPU}" \
    AnalyzeContainerMemory="${ANALYZE_CONTAINER_MEMORY}" \
    AnalyzeDesiredCount="${ANALYZE_DESIRED_COUNT}" \
    AnalyzeImageTag="${ANALYZE_IMAGE_TAG}" \
    ApplicationTag="${APPLICATION_TAG}" \
    CapacityProvider="${CAPACITY_PROVIDER}" \
    ContainerRegistry="${CONTAINER_REGISTRY}" \
    DomainName="${DOMAIN_NAME}" \
    FrontendContainerCpu="${FRONTEND_CONTAINER_CPU}" \
    FrontendContainerMemory="${FRONTEND_CONTAINER_MEMORY}" \
    FrontendDesiredCount="${FRONTEND_DESIRED_COUNT}" \
    FrontendImageTag="${FRONTEND_IMAGE_TAG}" \
    HostedZoneId="${HOSTED_ZONE_ID}" \
    JobsContainerCpu="${JOBS_CONTAINER_CPU}" \
    JobsContainerMemory="${JOBS_CONTAINER_MEMORY}" \
    JobsDesiredCount="${JOBS_DESIRED_COUNT}" \
    JobsImageTag="${JOBS_IMAGE_TAG}" \
    KeycloakContainerCpu="${KEYCLOAK_CONTAINER_CPU}" \
    KeycloakContainerMemory="${KEYCLOAK_CONTAINER_MEMORY}" \
    KeycloakDesiredCount="${KEYCLOAK_DESIRED_COUNT}" \
    KeycloakImageTag="${KEYCLOAK_IMAGE_TAG}" \
    KeycloakRdsDbClass="${KEYCLOAK_RDS_DB_CLASS}" \
    LogsRetention="${LOGS_RETENTION}" \
    PrivateSubnets="${PRIVATE_SUBNETS}" \
    PublicSubnets="${PUBLIC_SUBNETS}" \
    Vpc="${VPC}" \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
