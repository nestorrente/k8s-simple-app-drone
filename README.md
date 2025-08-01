# Drone Helm K8s

[![GitHub license](https://img.shields.io/github/license/nestorrente/k8s-simple-app-drone.svg)](./LICENSE)

> **_DISCLAIMER:_**  this repository is just a proof of concept that isn't meant to be used by any means at a company. Use it at your own risk.
 
## Description 
Generic [Drone](drone.io) extension for deploying applications to Kubernetes clusters using a generic Helm chart. 

This extension acts as a simple interface between the Helm chart and a CI/CD pipeline. All details of the chart can be found [here](https://github.com/nestorrente/k8s-simple-app-chart). 

Inspired by [Rubén Pahino's chart](https://github.com/rubasace/drone-helm-k8s), this extension pretends to be the one used on the deployment process of our applications. This way a team/company can centralize all good-practices and standardize their deployment process in a friction-less manner.

## How to use

### Pipeline definition

To use it, first you have to plug the step on the drone pipeline. An example where we bake an image and deploy it would look like this:

```yaml
kind: pipeline
name: default

steps:
    # Create the docker image
  - name: bake
    image: plugins/docker
    settings:
      username: *******
      password: *******
      repo: registry.mycompany.com/v2/team1/demo
      registry: registry.mycompany.com/v2
      tags: 1.0.0.${CI_BUILD_NUMBER}
    when:
      branch:
        - master
    # Deploy the docker image using the extension
  - name: deploy
    image: nestorrente/k8s-simple-app-drone
    environment:
      CHART_VERSION_ARGUMENT: 0.1.24
      K8S_CERT_AUTHORITY_DATA:
        from_secret: K8S_CERT_AUTHORITY_DATA
      K8S_SERVER:
        from_secret: K8S_SERVER
      K8S_USER:
        from_secret: K8S_USER
      K8S_PASSWORD:
        from_secret: K8S_PASSWORD
      NAMESPACE: production
      IMAGE_TAG: 1.0.0.${CI_BUILD_NUMBER}
    when:
      branch:
        - master
``` 

In order to configure the deployment, we have to specify a few environment variables:

| Variable                 | Description                                                                   | Mandatory | Example Value                                | 
|--------------------------|-------------------------------------------------------------------------------|---|----------------------------------------------|
| CHART_VERSION_ARGUMENT   | Version of the Helm Chart to use.*                                            | `false` | 0.1.24                                       |
| K8S_CERT_AUTHORITY_DATA  | `certificate-authority-data` value on the Kubernetes config file.             | `true` | LS0tLS2CRUdPFiBDRVJUSUZJQ0FURSOtLS98URKtC... |
| K8S_SERVER               | `server` value on the Kubernetes config file.                                 | `true` | https://29.29.29.29:16443                    |
| K8S_TOKEN                | auth token to access the cluster.                                             |`true`  | eyJhbGciOiJSU...                             |
| NAMESPACE                | K8s namespace to deploy the application in.                                   |  `true` | production                                   |
| IMAGE_TAG                | Tag of the image to deploy. It should be the same generated on the bake step. | `true`  |                                              | 1.0.0.${CI_BUILD_NUMBER}  |

* It's recomended to specify the chart version, to ensure the deployment is reproducible and to avoid surprises when the chart evolves independently of the application.

> **_NOTE:_** this extension has been tested in POCs against [microk8s](https://microk8s.io/) clusters. Other k8s distributions like GKE might not connect in the same way. It should be easy to adapt by changing the logic of replacing the `kube_config_template.yaml` values in the `entrypoint.sh` script for something more suitable. 

### General values

This extension will look for a `values.yaml` file in the directory `.k8s` of the repository. This is the way the chart can be customized for a specific deployment. One example of `.k8s/values.yaml` would be:

```yaml
ingress:
  enabled: true
  domain: mycompany.com
deployment:
  image: registry.mycompany.com/v2/team1/demo
  containerPort: 8080
  imagePullSecrets:
    - regcred
```

Those are the values that will be passed to the Helm chart when deploying the application. For a full list of the supported values, have a look at the chart documentation.

> **_NOTE:_** the image has to be the one generated in the bake stage. At the moment cannot be automatically guessed by the extension.

### Namespace-specific values

This extension supports overlaying of values, by creating additional `values-{namespace}.yaml` files. While it isn't mandatory, this mechanism is key in order to avoid repetition of values: all common values for every environment can be specified in the `values.yaml` file, only putting the environment-specific values in separate files

Following the previous example, we might want to override the domain as well as specify a subdomain for the deployment to the namespace staging. We can create the file `.k8s/values-staging.yaml` as follows:

```yaml
ingress:
  domain: mycompanystaging.com
  subdomain: demo
```

The application repository would look something like this:

```text
├── .k8s
│   └── values.yaml
│   └── values-production.yaml
│   └── values-staging.yaml
├── Dockerfile
├── README.md
├── ...
```

In both cases, all values in `values.yaml` will be set first and then will be complemented/overriden by the ones in the environment-specific files. 

## Usage with other tools

This extension was created to be used with Drone, but it can be easily adapted to any other Docker based CI/CD tool such as CircleCI. It's as simple as replacing the few Drone specific environment variables with the ones provided by the tool of your choice.

## Notes
While this extension works out-of-the-box, it's too generic for being used as it is. Things like the domain are left in the air, so it's a good practice to just extend/fork [the Helm chart](https://github.com/nestorrente/k8s-simple-app-chart) in
order to adapt it to your specific scenario, instead of having to provide the same values over and over again. Then it would be a matter of making this extension point to your forked chart.
