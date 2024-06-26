SHELL                   = /bin/bash

ROS_DISTRO             ?= noetic
BUILDER_NAME            = seqsense/aports-ros-builder
ALPINE_VERSION         ?= 3.17
S3_APK_REPO_BUCKET_URI ?= s3://localhost
S3_APK_REPO_MIRROR_URI ?=
APK_REPO_PRIVATE_KEY   ?= # path to your private key
JOBS                   ?= 2
RESIGN                 ?= false
STACK_PROTECTOR        ?= on
KEEP_GOING             ?=

BUILDER_TAG             = $(ROS_DISTRO).v$(ALPINE_VERSION)

REPOSITORY              = backports ros/$(ROS_DISTRO)

ifeq ($(shell if [ -f "${APK_REPO_PRIVATE_KEY}" ]; then echo true; fi), true)
	PRIVATE_KEY_OPT = -v $(APK_REPO_PRIVATE_KEY):/home/builder/.abuild/builder@alpine-ros-experimental.rsa:ro
endif

.PHONY: build-builder
build-builder:
	docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--cache-from=$(BUILDER_NAME):$(BUILDER_TAG) \
		-t $(BUILDER_NAME):$(BUILDER_TAG) .

.PHONY: cache-dir
cache-dir:
	mkdir -p packages/.cache/v$(ALPINE_VERSION)/ccache
	chmod og+rwx packages/.cache/v$(ALPINE_VERSION)/ccache
	mkdir -p packages/.cache/v$(ALPINE_VERSION)/apk
	chmod og+rwx packages/.cache/v$(ALPINE_VERSION)/apk

.PHONY: $(REPOSITORY)
$(REPOSITORY): cache-dir
	if [ ! -d packages/v$(ALPINE_VERSION)/$(notdir $@) ]; then \
		mkdir -p packages/v$(ALPINE_VERSION)/$(notdir $@); \
		chmod og+rwx packages/v$(ALPINE_VERSION)/$(notdir $@); \
	fi
	docker run --rm -it \
		-v $(CURDIR):/src \
		-v $(CURDIR)/packages/v$(ALPINE_VERSION):/home/builder/packages \
		-v $(CURDIR)/packages/.cache/v$(ALPINE_VERSION)/ccache:/cache/ccache \
		-v $(CURDIR)/packages/.cache/v$(ALPINE_VERSION)/apk:/etc/apk/cache \
		$$(if [ '$@' != 'backports' ]; then echo "-v $(CURDIR)/packages/v$(ALPINE_VERSION)/backports:/home/builder/deps.rw/backports"; fi) \
		$(PRIVATE_KEY_OPT) \
		-e JOBS=${JOBS} \
		-e PURGE_OBSOLETE=yes \
		-e STACK_PROTECTOR=$(STACK_PROTECTOR) \
		-e KEEP_GOING=$(KEEP_GOING) \
		-e RESIGN=true \
		--name aports-ros-experimental-v$(ALPINE_VERSION)-$(subst /,-,$@) \
		$(BUILDER_NAME):$(BUILDER_TAG) v$(ALPINE_VERSION)/$@

.PHONY: s3-pull
s3-pull:
	aws s3 sync --no-sign-request $(S3_APK_REPO_BUCKET_URI)/v$(ALPINE_VERSION) packages/v$(ALPINE_VERSION)
	chmod -Rf og+rw packages/v$(ALPINE_VERSION) || true

.PHONY: s3-push
s3-push:
	aws s3 sync --acl=public-read --delete packages/v$(ALPINE_VERSION) $(S3_APK_REPO_BUCKET_URI)/v$(ALPINE_VERSION)
	aws s3 sync --acl=public-read packages/v$(ALPINE_VERSION) $(S3_APK_REPO_BUCKET_URI)/archives/v$(ALPINE_VERSION)

.PHONY: s3-push-mirror
s3-push-mirror:
	if [ -n "$(S3_APK_REPO_MIRROR_URI)" ]; then \
		aws s3 sync --delete --acl bucket-owner-full-control packages/v$(ALPINE_VERSION) $(S3_APK_REPO_MIRROR_URI)/v$(ALPINE_VERSION); \
		aws s3 sync --acl bucket-owner-full-control packages/v$(ALPINE_VERSION) $(S3_APK_REPO_MIRROR_URI)/archives/v$(ALPINE_VERSION); \
	fi

.PHONY: all
all:
	$(MAKE) s3-pull
	$(MAKE) build-builder
	$(MAKE) $(REPOSITORY)

UPDATE_TARGETS ?=
export UPDATE_TARGETS

.PHONY: update-checksum
update-checksum:
	docker run --rm \
		-v $(CURDIR):/src \
		--entrypoint /update-checksum.sh \
		$(BUILDER_NAME):$(BUILDER_TAG) $${UPDATE_TARGETS}
