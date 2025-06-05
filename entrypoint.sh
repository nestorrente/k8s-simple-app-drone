#!/usr/bin/env sh

set -x
set -e

#KUBECONFIG setup
#TODO support envsubst on values files
envsubst < /.kube/config_template > /.kube/config
rm /.kube/config_template

# Helm preparation
# TODO support chart version specification
#export CHART_VERSION_ARGUMENT="--version 0.1.0"
export CHART_VERSION_ARGUMENT=""
export RELEASE_NAME="${RELEASE_NAME:=${DRONE_REPO_NAME}}"
export TIMEOUT="${TIMEOUT:=5m}"

VALUES_FILE=".k8s/values.yaml"
VALUES_TEMPLATE_FILE=".k8s/values.template.yaml"

if test -f "$VALUES_TEMPLATE_FILE"; then
  envsubst < "$VALUES_TEMPLATE_FILE" > "$VALUES_FILE"
fi

# If environment-specific (namespace) file exists, then we apply it after the generic 'values.yaml' file, to overlay environment-specific values
ENV_SPECIFIC_VALUES_FILE=".k8s/values-${NAMESPACE}.yaml"
ENV_SPECIFIC_VALUES_TEMPLATE_FILE=".k8s/values-${NAMESPACE}.template.yaml"

if test -f "$ENV_SPECIFIC_VALUES_TEMPLATE_FILE"; then
  envsubst < "$ENV_SPECIFIC_VALUES_TEMPLATE_FILE" > "$ENV_SPECIFIC_VALUES_FILE"
fi

if test -f "$ENV_SPECIFIC_VALUES_FILE"; then
  export ENV_VALUES_ARGUMENT="-f ${ENV_SPECIFIC_VALUES_FILE}"
fi

helm repo add k8s-chart https://nestorrente.github.io/k8s-simple-app-chart/

# TODO make Helm fail when deployment fails
helm upgrade "${RELEASE_NAME}"  k8s-chart/k8s-simple-app ${CHART_VERSION_ARGUMENT} --install -n ${NAMESPACE} --atomic --debug --wait --timeout ${TIMEOUT} \
--set deployment.tag=${IMAGE_TAG} -f ${VALUES_FILE} ${ENV_VALUES_ARGUMENT}
