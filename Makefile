registry="ghcr.io"
namespace="ohyee"
repo="devcontainer"

NODEJS_VERSION ?= "20.18.0"
GO_VERSION ?= "1.21.11"
PYTHON_VERSION ?= "3.10.9"

tag=${NODEJS_VERSION}-${GO_VERSION}-${PYTHON_VERSION}

.PHONY: build
build:
	echo ${registry}/${namespace}/${repo}:${tag}
	docker build -t ${registry}/${namespace}/${repo}:${tag} \
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		--build-arg NODEJS_VERSION=${NODEJS_VERSION} \
		--build-arg GO_VERSION=${GO_VERSION} \
		.

.PHONY: push
push:
	docker push ${registry}/${namespace}/${repo}:${tag}

.PHONY: all
all: build push