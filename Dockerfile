FROM alpine/helm

ENV KUBECONFIG=/.kube/config

RUN apk add --update --no-cache gettext

COPY kube_config_template.yaml /.kube/config_template

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
