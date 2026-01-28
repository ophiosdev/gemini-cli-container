# Simple Makefile to build and clean the local Docker image

IMAGE ?= gemini-cli
TAG ?= dev
IMAGE_REF := $(IMAGE):$(TAG)
DOCKERFILE ?= Dockerfile
CONTEXT ?= .
GEMINI_CLI_VERSION ?= latest

.PHONY: build clean

build:
	docker build \
		-t $(IMAGE_REF) \
		-f $(DOCKERFILE) \
		--build-arg GEMINI_CLI_VERSION=$(GEMINI_CLI_VERSION) \
		$(CONTEXT)

clean:
	@echo "Removing image $(IMAGE_REF) if it exists..."
	- docker image inspect $(IMAGE_REF) >/dev/null 2>&1 && docker rmi $(IMAGE_REF) || true
