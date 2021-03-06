# Code generated by github.com/aiicy/aiicy/sdk/aiicy-go/generate.go. DO NOT EDIT.
# source: github.com/aiicy/aiicy/sdk/aiicy-go/templates/Makefile-python

MODULE:=application-nlu
BIN_FILE:=nlu.py
#BIN_CMD=install -m 0755 $(SRC_FILES) $(dir $@) && cd $(dir $@)
COPY_DIR:=.
PLATFORM_ALL:=darwin/amd64 linux/amd64 linux/arm64 linux/386 linux/arm/v7
GIT_TAG:=$(shell git tag --contains HEAD)
GIT_REV:=git-$(shell git rev-parse --short HEAD)
VERSION:=$(if $(GIT_TAG),$(GIT_TAG),$(GIT_REV))

ifndef PLATFORMS
	GO_OS:=$(shell go env GOOS)
	GO_ARCH:=$(shell go env GOARCH)
	GO_ARM:=$(shell go env GOARM)
	PLATFORMS:=$(if $(GO_ARM),$(GO_OS)/$(GO_ARCH)/$(GO_ARM),$(GO_OS)/$(GO_ARCH))
	ifeq ($(GO_OS),darwin)
		PLATFORMS+=linux/amd64
	endif
else ifeq ($(PLATFORMS),all)
	override PLATFORMS:=$(PLATFORM_ALL)
endif

REGISTRY?=
XFLAGS?=--load
XPLATFORMS:=$(shell echo $(filter-out darwin/amd64,$(PLATFORMS)) | sed 's: :,:g')

CONF_FILE=service.yml
MODEL_FILE:=$(shell find models/ -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

OUTPUT:=../../out
#OUTPUT_MODS:=$(PLATFORMS:%=$(OUTPUT)/%/$(MODULE))
OUTPUT_MODS:=$(OUTPUT:%=%/var/db/aiicy/$(MODULE))
OUTPUT_BINS:=$(OUTPUT_MODS:%=%/$(BIN_FILE))

.PHONY: all
all: $(OUTPUT_BINS)

$(OUTPUT_BINS): $(BIN_FILE)
	@echo "BUILD $@"
	@install -d -m 0755 $(dir $@)
	@$(if $(strip $(MODEL_FILE)),,echo -e "\033[0;31mcan't find nlu model file in models/\033[0m" && exit 1)
	@rm -rf tmp && mkdir tmp && tar xvzf $(MODEL_FILE) -C tmp/
	@ln -s $(abspath tmp/nlu) $(OUTPUT_MODS)/models
	@ln -s $(abspath data) $(OUTPUT_MODS)/data
	@ln -s $(abspath $(BIN_FILE)) $(OUTPUT_MODS)/
	@#$(BIN_CMD)

.PHONY: image
image: $(OUTPUT_BINS)
	@echo "BUILDX: $(REGISTRY)$(MODULE):$(VERSION)"
	@-docker buildx create --name aiicy
	@docker buildx use aiicy
	docker buildx build $(XFLAGS) --platform $(XPLATFORMS) -t $(REGISTRY)$(MODULE):$(VERSION) -f Dockerfile $(COPY_DIR)

.PHONY: train
train:
	@mkdir -p models/zh
	@rasa train --config configs/zh.yml --data data/zh/ --out models/zh

.PHONY: gen
gen:
	@python -m scripts.trainsfer_raw_to_rasa --input data/zh/raw/raw_data.txt --output data/zh/train_data.json

.PHONY: rebuild
rebuild: clean all

.PHONY: clean
clean:
	@find $(OUTPUT) -type d -name $(MODULE) | xargs rm -rf


