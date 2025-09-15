# Makefile for gpu-algo-dev Container
# Supports building, tagging, and pushing to Docker Hub

# Container configuration
IMAGE_NAME := gpu-algo-dev
DOCKER_HUB_USER := mikesrnd
VERSION := $(shell cat VERSION)

# Full image names
LOCAL_IMAGE := $(IMAGE_NAME):latest
LOCAL_VERSIONED := $(IMAGE_NAME):$(VERSION)
HUB_IMAGE := $(DOCKER_HUB_USER)/$(IMAGE_NAME):latest
HUB_VERSIONED := $(DOCKER_HUB_USER)/$(IMAGE_NAME):$(VERSION)

.PHONY: help build tag push release clean version login

help:
	@echo "Available targets:"
	@echo "  build      - Build the container image"
	@echo "  tag        - Tag the image with version and Docker Hub namespace"
	@echo "  push       - Push the image to Docker Hub (requires docker login)"
	@echo "  release    - Build, tag, and push (full release)"
	@echo "  clean      - Remove local images"
	@echo "  version    - Show current version"
	@echo "  login      - Login to Docker Hub"
	@echo ""
	@echo "Current version: $(VERSION)"
	@echo "Docker Hub user: $(DOCKER_HUB_USER)"

build:
	@echo "Building container image: $(LOCAL_IMAGE)"
	docker build -t $(LOCAL_IMAGE) .
	@echo "Build complete: $(LOCAL_IMAGE)"

tag: build
	@echo "Tagging image with version: $(VERSION)"
	docker tag $(LOCAL_IMAGE) $(LOCAL_VERSIONED)
	docker tag $(LOCAL_IMAGE) $(HUB_IMAGE)
	docker tag $(LOCAL_IMAGE) $(HUB_VERSIONED)
	@echo "Tagged as:"
	@echo "  - $(LOCAL_VERSIONED)"
	@echo "  - $(HUB_IMAGE)"
	@echo "  - $(HUB_VERSIONED)"

push: tag
	@echo "Pushing to Docker Hub..."
	@echo "Note: Make sure you're logged in with 'make login' or 'docker login'"
	docker push $(HUB_IMAGE)
	docker push $(HUB_VERSIONED)
	@echo "Push complete!"
	@echo "Images available at:"
	@echo "  - docker.io/$(HUB_IMAGE)"
	@echo "  - docker.io/$(HUB_VERSIONED)"

release: build tag push
	@echo "Release $(VERSION) complete!"

clean:
	@echo "Removing local and hub-tagged images..."
	-docker rmi $(LOCAL_IMAGE) 2>/dev/null
	-docker rmi $(LOCAL_VERSIONED) 2>/dev/null
	-docker rmi $(HUB_IMAGE) 2>/dev/null
	-docker rmi $(HUB_VERSIONED) 2>/dev/null
	@echo "Clean complete"

version:
	@echo "$(VERSION)"

login:
	@echo "Logging in to Docker Hub as $(DOCKER_HUB_USER)"
	docker login -u $(DOCKER_HUB_USER)