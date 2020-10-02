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

### Configuration

Currently the frontend, adapter and runner applications needs to load configuration files from an S3 storage that is created by the infrastructure template. We've included templates for these files in the [config directory](./config).

Before uploading these configuration files, you first need to remove the `_template` suffix from the file name. Second you need to set any values that are needed.

- `config/frontend/keycloak.json` is needed if you're using Keycloak as your authentication solution, in it you'll need to replace `AV_KEYCLOAK_URL` to include the URL of you Keycloak Realm.

- `config/frontend/settings.js` contains the frontend configuration where you'll need to replace `AV_LICENSE_KEY` with a valid Accurate Video license key, and configure how the frontend should behave

- `config/backend/cluster.xml` contains a Hazelcast configuration that is shared between Adapter and Jobs to talk over an event bus instead of polling.

After you've renamed and updated the configuration files you'll need to upload them to the configuration bucket that was created by the infrastructure template.

```sh
aws s3 cp --recursive ./config/frontend s3://${CONFIG_BUCKET}/frontend
aws s3 cp --recursive ./config/backend s3://${CONFIG_BUCKET}/backend
```

### Adapter/Backend

### Frontend

### Analyze

### Jobs/Runner
