From golang:1.10.3-stretch

RUN apt-get update && apt-get install -y bzip2 && \
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh && \
    curl -o gitlab-operator.tar.bz2 https://gitlab.com/gitlab-org/distribution/gitlab-operator/-/archive/allow-incluster-config/gitlab-operator-gitlab-operator.tar.bz2  && \
    tar -xjf gitlab-operator.tar.bz2 && \
    mv gitlab-operator-* gitlab-operator && \
    export GOPATH=$(pwd)/gitlab-operator && \
    cd gitlab-operator/src/gitlab.com/gitlab-org/distribution/gitlab-operator && \
    dep ensure -v && go build -o gitlab-operator *.go && \
    chmod +x gitlab-operator && \
    cp gitlab-operator /usr/local/bin/gitlab-operator
