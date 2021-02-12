#!/usr/bin/env bash

PROFILE="${1}"
REGION="${2}"

if [ -z "${PROFILE}" ] ; then
  read -rp "AWS Profile: " PROFILE
fi

if [ -z "${REGION}" ] ; then
  read -rp "AWS Region: " REGION
fi

read -rp "Registry username (required): " REGISTRY_USERNAME
read -rp "Registry password (required): " REGISTRY_PASSWORD

# Create docker pull secret
aws secretsmanager create-secret \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --name codemill-jfrog-docker \
  --secret-string "{\"username\":\"${REGISTRY_USERNAME}\",\"password\":\"${REGISTRY_PASSWORD}\"}"

# Print docker pull secret ARN
aws secretsmanager describe-secret \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --secret-id codemill-jfrog-docker | jq '.ARN'
