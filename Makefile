.PHONY: build pull

PROXY=http://127.0.0.1:17890
IMAGE_NAME=playground

build: Dockerfile
	docker build \
		--build-arg http_proxy=$(PROXY) \
		--build-arg https_proxy=$(PROXY) \
		--network=host \
		--tag $(IMAGE_NAME) \
		--file $< \
		.
