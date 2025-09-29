# Container image build and release helpers
IMAGE_NAME ?= mikesrnd/gpu-algo-dev
VERSION ?= $(shell cat VERSION)

.PHONY: container-dev-help container-build container-release container-clean container-version container-login

container-dev-help:
	@echo "Container Build & Publish Commands:"
	@echo "  container-build    - Build the container image locally"
	@echo "  container-release  - Tag with version and push to Docker Hub"
	@echo "  container-clean    - Remove local images"
	@echo "  container-version  - Show current version"
	@echo "  container-login    - Login to Docker Hub"

container-build:
	@echo "Building container image: $(IMAGE_NAME):latest"
	docker build --build-arg BUILD_SOURCE=local --build-arg BUILD_TIME=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") -t $(IMAGE_NAME):latest .
	@echo "Build complete: $(IMAGE_NAME):latest"

container-release: container-build
	@echo "Tagging and pushing version: $(VERSION)"
	docker tag $(IMAGE_NAME):latest $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):$(VERSION)
	@echo "Release $(VERSION) complete!"
	@echo "Images available at:"
	@echo "  - docker.io/$(IMAGE_NAME):latest"
	@echo "  - docker.io/$(IMAGE_NAME):$(VERSION)"

container-clean:
	@echo "Removing local images..."
	-docker rmi $(IMAGE_NAME):latest 2>/dev/null
	-docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null
	@echo "Clean complete"

container-version:
	@echo "$(VERSION)"

container-login:
	@echo "Logging in to Docker Hub as mikesrnd"
	docker login -u mikesrnd