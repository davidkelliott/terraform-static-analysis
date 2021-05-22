# pinned version of the Alpine-tagged 'go' image
#FROM golang:1.16-alpine
FROM golang:1.16-stretch

RUN apt-get update && apt-get install -y \
  python3-pip \
  git \
  golang-go \
  && rm -rf /var/lib/apt/lists/*
# install requirements
# RUN apk add --update --no-cache bash ca-certificates curl jq python3 py3-pip git
#RUN apk add --update --no-cache bash ca-certificates curl jq py3-pip
RUN pip3 install --upgrade pip && pip3 install --upgrade setuptools
RUN pip3 install checkov

COPY entrypoint.sh /entrypoint.sh
# set the default entrypoint -- when this container is run, use this command
ENTRYPOINT ["/entrypoint.sh"]