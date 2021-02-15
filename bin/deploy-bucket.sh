#!/usr/bin/env bash

PROFILE="${1}"
REGION="${2}"
STACK_NAME="${3}"

if [ -z "${PROFILE}" ] ; then
  read -rp "AWS Profile: " PROFILE
fi

if [ -z "${REGION}" ] ; then
  read -rp "AWS Region: " REGION
fi

if [ -z "${STACK_NAME}" ] ; then
  read -rp "Stack name: " STACK_NAME
fi

aws cloudformation deploy \
  --template-file ./bucket.yaml \
  --stack-name "${STACK_NAME}" \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --capabilities CAPABILITY_IAM

aws cloudformation describe-stack-resources \
  --stack-name "${STACK_NAME}" \
  --profile "${PROFILE}" \
  --region "${REGION}" | jq '.StackResources[].PhysicalResourceId'
