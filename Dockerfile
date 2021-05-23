FROM golang:1.16-buster

RUN apt-get update && apt-get install -y \
  python3.7 \
  python3-pip \
  git \
  jq \
  && rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip && pip3 install --upgrade setuptools
RUN pip3 install checkov

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
