.PHONY: build pull

PROXY=http://127.0.0.1:17890
IMAGE_NAME=playground

build: Dockerfile
	docker build \
		--build-arg https_proxy=$(PROXY) \
		--build-arg UID=$(shell id -u) \
		--build-arg GID=$(shell id -g) \
		--network=host \
		--tag $(IMAGE_NAME) \
		--file $< \
		.