#!/usr/bin/env bash

SCRIPT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
# shellcheck source=../bin/lib/env
source "$SCRIPT_ROOT/lib/env"

# shellcheck source=lib/log/log.sh
source "$LIB_ROOT/log/log.sh"

set -o allexport
# shellcheck source=../.env
[[ -f .env ]] && source .env
set +o allexport



options=$(getopt \
  --options "" \
  --longoptions help,region,profile: \
  -- "$@")
eval set --"$options"

REGION=eu-west-1

usage() {
  echo "Usage: $0 [--region=<aws-region>] [--help]"
  echo -e "\t--help \n\t\tdescribes how to use the tool"
  echo -e "\t--region \n\t\twhich region to deploy to \n\t\t(DEFAULT = $REGION)"
  echo -e "\t--profile \n\t\twhich configured aws profile to use for the deployment\n"
  echo ""
  echo -e "Deploys AV in a custom setup in AWS"
  echo ""

  exit 1
}

while true; do
  case "$1" in
  --region)
    shift
    REGION="$1"
    ;;

  --profile)
    shift
    PROFILE="$1"
    ;;

  --help)
    usage
    exit 1
    ;;

  --)
    shift
    break
    ;;
  esac
  shift
done

if [ -z "${PROFILE}" ] ; then
  read -rp "AWS Profile: " PROFILE
fi

log_info "Deploying to region: $REGION"
log_info "With profile: $PROFILE"

aws cloudformation package \
  --template-file "$PROJECT_ROOT"/main.yaml \
  --output-template "$PROJECT_ROOT"/packaged.yaml \
  --s3-bucket "${TEMPLATE_BUCKET_NAME}" \
  --profile "${PROFILE}" \
  --region "${REGION}"

aws cloudformation deploy \
  --template-file "$PROJECT_ROOT"/packaged.yaml \
  --stack-name "${STACK_NAME}" \
  --profile "${PROFILE}" \
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
    RegistrySecretArn="${REGISTRY_SECRET_ARN}" \
    Vpc="${VPC}" \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
