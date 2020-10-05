read -p 'AWS Region: ' REGION
read -p 'AWS Profile [default]: ' PROFILE
read -p 'Infrastructure stack name [av-ecs]: ' INFRASTRUCTURE_STACK_NAME
read -p 'Cluster name [av-cluster]: ' CLUSTER_NAME
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

aws cloudformation wait stack-create-complete \
    --stack-name "${INFRASTRUCTURE_STACK_NAME}" \
    --region "${REGION}" \
    --profile "${PROFILE}"
  
WAIT_STACK_CREATE_CODE=$?
if [ WAIT_STACK_CREATE_CODE != "0" ]; then
  printf 'ERR: Failed waiting for stack %s to complete: %s\n' "${INFRASTRUCTURE_STACK_NAME}" "${WAIT_STACK_CREATE_CODE}" >&2
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
