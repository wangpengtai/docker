from alpine:3.6
RUN apk add --no-cache curl bash openssl && \
    curl -LsO https://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kubectl && \
    chmod +x kubectl && mv ./kubectl /usr/local/bin/kubectl
