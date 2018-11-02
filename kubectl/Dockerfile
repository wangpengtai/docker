ARG KUBECTL_VERSION="v1.9.3"
FROM debian:stretch-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates libssl1.0.2 openssh-client \
  && curl -LsO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod +x kubectl \
  && mv kubectl /usr/local/bin/kubectl
