RELEASE = $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
COMMIT = $(shell git rev-parse HEAD || echo -n NOTGIT)

SHELL = bash

REPO ?= openmicroscopy
ORIGIN ?= origin

usage:
	@echo "Usage:"
	@echo " "
	@echo "  make VERSION=x.y.z git-tag                          #   Update Dockerfile, commit and tag"
	@echo "  make VERSION=x.y.z BUILD=1 git-tag                  #   Re-tag, e.g. when a new upstream is released"
	@echo " "
	@echo "  # Release Candidate"
	@echo "  make VERSION=x.y.z ORIGIN=snoopycrimecop git-push   #   Push to another git remote"
	@echo "  make VERSION=x.y.z REPO=snoopycrimecop docker-build #   Build and tag images for another hub account"
	@echo "  make VERSION=x.y.z REPO=snoopycrimecop docker-push  #   Push images to another hub account"
	@echo " "
	@echo "  # Release"
	@echo "  make VERSION=x.y.z git-push                         #   Push to $(ORIGIN)"
	@echo "  make VERSION=x.y.z docker-build                     #   Build and tag images for $(REPO) hub repo"
	@echo "  make VERSION=x.y.z docker-push                      #   Push images to $(REPO) hub repo"
	@echo " "
	@echo "  # Dev Release"
	@echo "  make VERSION=x.y.z git-push                         #   Push to $(ORIGIN)"
	@echo "  make VERSION=x.y.z docker-build-versions            #   Skips tagging latest"
	@echo "  make VERSION=x.y.z docker-push-versions             #   Skips pushing latest"


git-tag:
ifndef VERSION
	$(error VERSION is undefined)
endif

	perl -i -pe 's/OMERO_VERSION=(\S+)/OMERO_VERSION=$(VERSION)/' Dockerfile
	perl -i -pe 's/(org.opencontainers.image.created=)"([^"]+)"/$$1"$(RELEASE)"/' Dockerfile
	perl -i -pe 's/(org.opencontainers.image.revision=)"([^"]+)"/$$1"$(COMMIT)"/' Dockerfile

ifndef BUILD
	git commit -a -m "Bump OMERO_VERSION to $(VERSION)"
	git tag -s -m "Tag version $(VERSION)" $(VERSION)
else
	git commit -a -m "Re-build $(BUILD) of OMERO_VERSION $(VERSION)"
	git tag -s -m "Re-tag $(VERSION) with suffix $(BUILD)" $(VERSION)-$(BUILD)
endif


git-push:
ifndef VERSION
	$(error VERSION is undefined)
endif

ifndef BUILD
	git push $(ORIGIN) $(VERSION)
else
	git push $(ORIGIN) $(VERSION)-$(BUILD)
endif


docker-build-versions:
ifndef VERSION
	$(error VERSION is undefined)
endif
ifndef BUILD
	$(eval BUILD=0)
endif
	docker build $(BUILDARGS) -t $(REPO)/omero-server:$(VERSION)-$(BUILD) .
	docker tag $(REPO)/omero-server:$(VERSION)-$(BUILD) $(REPO)/omero-server:$(VERSION)
	@MAJOR_MINOR=$(shell echo $(VERSION) | cut -f1-2 -d. );\
	docker tag $(REPO)/omero-server:$(VERSION)-$(BUILD) $(REPO)/omero-server:$$MAJOR_MINOR

	docker build --build-arg=PARENT_IMAGE=$(REPO)/omero-server:$(VERSION) -t $(REPO)/omero-server-extras:$(VERSION)-$(BUILD) extras
	docker tag $(REPO)/omero-server-extras:$(VERSION)-$(BUILD) $(REPO)/omero-server-extras:$(VERSION)
	@MAJOR_MINOR=$(shell echo $(VERSION) | cut -f1-2 -d. );\
	docker tag $(REPO)/omero-server-extras:$(VERSION)-$(BUILD) $(REPO)/omero-server-extras:$$MAJOR_MINOR


docker-build: docker-build-versions
	docker tag $(REPO)/omero-server:$(VERSION)-$(BUILD) $(REPO)/omero-server:latest
	docker tag $(REPO)/omero-server-extras:$(VERSION)-$(BUILD) $(REPO)/omero-server-extras:latest


docker-push-versions:
ifndef VERSION
	$(error VERSION is undefined)
endif
ifndef BUILD
	$(eval BUILD=0)
endif
	docker push $(REPO)/omero-server:$(VERSION)-$(BUILD)
	docker push $(REPO)/omero-server:$(VERSION)
	@MAJOR_MINOR=$(shell echo $(VERSION) | cut -f1-2 -d. );\
	docker push $(REPO)/omero-server:$$MAJOR_MINOR

	docker push $(REPO)/omero-server-extras:$(VERSION)-$(BUILD)
	docker push $(REPO)/omero-server-extras:$(VERSION)
	@MAJOR_MINOR=$(shell echo $(VERSION) | cut -f1-2 -d. );\
	docker push $(REPO)/omero-server-extras:$$MAJOR_MINOR

docker-push: docker-push-versions
	docker push $(REPO)/omero-server:latest
	docker push $(REPO)/omero-server-extras:latest
