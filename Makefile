BUILDER_NAME            = aports-builder
ALPINE_VERSION          = 3.7
S3_APK_REPO_BUCKET_URI ?= s3://localhost
REPOSITORY              = backports
APK_REPO_PRIVATE_KEY   ?= # path to your private key

ifeq ($(shell if [ -f ${APK_REPO_PRIVATE_KEY} ]; then echo true; fi), true)
	PRIVATE_KEY_OPT = -v $(APK_REPO_PRIVATE_KEY):/home/builder/.abuild/builder@alpine-ros-experimental.rsa:ro
endif

.PHONY: build-builder
build-builder:
	docker build -t $(BUILDER_NAME):$(ALPINE_VERSION) .

.PHONY: $(REPOSITORY)
$(REPOSITORY):
	mkdir -p packages/v$(ALPINE_VERSION)/$(REPOSITORY)
	chmod og+rwx packages/v$(ALPINE_VERSION)/$(REPOSITORY)
	docker run --rm -it \
		-v `pwd`:/src \
		-v `pwd`/packages/v$(ALPINE_VERSION)/$(REPOSITORY):/home/builder/packages/$(REPOSITORY) \
		$(PRIVATE_KEY_OPT) \
		$(BUILDER_NAME):$(ALPINE_VERSION) $(REPOSITORY)

.PHONY: s3-pull
s3-pull:
	aws s3 sync --no-sign-request $(S3_APK_REPO_BUCKET_URI)/v$(ALPINE_VERSION)/$(REPOSITORY) packages/v$(ALPINE_VERSION)/$(REPOSITORY)
	chmod -R og+rw packages/v$(ALPINE_VERSION)/$(REPOSITORY)

.PHONY: s3-push
s3-push:
	aws s3 sync --acl=public-read packages/v$(ALPINE_VERSION)/$(REPOSITORY) $(S3_APK_REPO_BUCKET_URI)/v$(ALPINE_VERSION)/$(REPOSITORY)

.PHONY: all
all:
	$(MAKE) s3-pull
	$(MAKE) build-builder
	$(MAKE) $(REPOSITORY)
	$(MAKE) s3-push
