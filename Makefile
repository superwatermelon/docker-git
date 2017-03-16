IMAGE_NAME := superwatermelon/git
tag := $(if $(TAG),$(TAG),test)

image:
	docker build --tag $(IMAGE_NAME):$(tag) .

test:
	IMAGE=$(IMAGE_NAME):$(tag) bats test/suite.bats

release:
	docker build --tag $(IMAGE_NAME):$(tag) .
	docker tag $(IMAGE_NAME):$(tag) $(IMAGE_NAME):latest
	scripts/docker-login
	docker push $(IMAGE_NAME):$(tag)
	docker push $(IMAGE_NAME):latest

.PHONY: image test release
