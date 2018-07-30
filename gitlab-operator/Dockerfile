From golang:1.10.3-stretch

RUN apt-get update && apt-get install -y bzip2 && \
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh && \
    curl -o gitlab-operator.tar.bz2 https://gitlab.com/Ahmadposten/gitlab-operator/-/archive/master/gitlab-operator-master.tar.bz2  && \
    tar -xjf gitlab-operator.tar.bz2 && \
    export GOPATH=$(pwd)/gitlab-operator-master && \
    cd gitlab-operator-master/src/gitlab.com/gitlab-org/distribution/gitlab-operator && \
    dep ensure -v && go build -o gitlab-operator *.go && \
    cp gitlab-operator /usr/local/bin/gitlab-operator
