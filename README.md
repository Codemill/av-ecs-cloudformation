# Accurate Video on AWS ECS

## Architecture

#### VPC
![alt text](documentation/network.png)

#### Security Groups
![alt text](documentation/security-groups.png)

### Services
![alt text](documentation/services.png)

### Auto-deployment of settings file
![alt text](documentation/autodeploy-settings-file.png)

## Deployment

### Infrastructure

> TODO(andreasolund): Add missing parameters needed to create the infrastructure stack

Create stack:

```sh
aws cloudformation update-stack \
  --template-body ./infrastructure.yaml \
  --stack-name av-ecs \
  --capabilities CAPABILITY_IAM
```

### Configuration

The Frontend, Adapter and Jobs applications currently loads configuration files from an S3 storage that is created by the infrastructure template. We've included templates for these files in the [config directory](./config) that you can use as your base of creating the proper configuration.

Before uploading each configuration file, you need to remove the `_template` suffix from the file name, and replace or set the values that are needed for your deployment.

- `config/frontend/keycloak.json` is needed if you're using Keycloak as your authentication solution, in it you'll need to replace `AV_KEYCLOAK_URL` with the URL of your Keycloak Realm.

- `config/frontend/settings.js` contains the frontend configuration, in it you'll need to replace `AV_LICENSE_KEY` with a valid Accurate Video license key, and configure the behaviour of the application.

- `config/backend/cluster.xml` contains a Hazelcast configuration that is shared between Adapter and Jobs to talk over an event bus instead of using a polling mechanism.

After you've renamed and updated the configuration files you'll need to upload them to the configuration bucket that was created by the infrastructure template.

```sh
aws s3 cp --recursive ./config/frontend s3://${CONFIG_BUCKET}/frontend
aws s3 cp --recursive ./config/backend s3://${CONFIG_BUCKET}/backend
```

### Applications

> TODO(andreasolund): Add missing parameters needed to create each stack

Create stacks:

```sh
aws cloudformation create-stack \
  --template-body ./av-frontend-deployment.yaml \
  --stack-name av-frontend \
  --parameters ParameterKey=StackName,ParameterValue=av-ecs

aws cloudformation create-stack \
  --template-body ./av-adapter-deployment.yaml \
  --stack-name av-adapter \
  --parameters ParameterKey=StackName,ParameterValue=av-ecs

aws cloudformation create-stack \
  --template-body ./av-jobs-deployment.yaml \
  --stack-name av-jobs \

aws cloudformation create-stack \
  --template-body ./av-analyze-deployment.yaml \
  --stack-name av-analyze \
  --parameters ParameterKey=StackName,ParameterValue=av-ecs
```

> TODO(andreasolund): Add missing parameters needed to update each stack

Update stacks:

```sh
aws cloudformation update-stack \
  --template-body ./av-frontend-deployment.yaml \
  --stack-name av-frontend \
  --parameters ParameterKey=StackName,ParameterValue=av-ecs

aws cloudformation update-stack \
  --template-body ./av-adapter-deployment.yaml \
  --stack-name av-adapter \
  --parameters ParameterKey=StackName,ParameterValue=av-ecs

aws cloudformation update-stack \
  --template-body ./av-jobs-deployment.yaml \
  --stack-name av-jobs \
  --parameters ParameterKey=StackName,ParameterValue=av-ecs
```
