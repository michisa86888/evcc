.PHONY: default clean install-backend install-ui lint-backend lint-ui test assets build binaries test-release release publish-testing publish-latest publish-images

TAG_NAME := $(shell test -d .git && git describe --abbrev=0 --tags || false)
SHA := $(shell test -d .git && git rev-parse --short HEAD)
VERSION := $(if $(TAG_NAME),$(TAG_NAME),$(SHA))
BUILD_DATE := $(shell date -u '+%Y-%m-%d_%H:%M:%S')

IMAGE := andig/evcc
ALPINE := 3.12
TARGETS := arm.v6,arm.v8,amd64

default: clean install ui assets lint test build

clean:
	rm -rf dist/

install-backend:
	go install github.com/mjibson/esc
	go install github.com/golang/mock/mockgen

install-ui:
	npm ci

install: install-backend install-ui

lint-backend:
	golangci-lint run

lint-ui:
	npm run lint

lint: lint-backend lint-ui

test:
	@echo "Running testsuite"
	go test ./...

npm:
	npm run build

ui:
	npm run build
	esc -o server/assets.go -pkg server -modtime 1566640112 -ignore .DS_Store dist

assets:
	@echo "Generating embedded assets"
	go generate ./...

build:
	@echo Version: $(VERSION) $(BUILD_DATE)
	go build -v -tags=release -ldflags '-X "github.com/andig/evcc/server.Version=${VERSION}" -X "github.com/andig/evcc/server.Commit=${SHA}"'

release-test:
	goreleaser --snapshot --skip-publish --rm-dist

release:
	goreleaser --rm-dist

publish-testing:
	@echo Version: $(VERSION) $(BUILD_DATE)
	seihon publish --dry-run=false --template docker/tmpl.Dockerfile --base-runtime-image alpine:$(ALPINE) \
	   --image-name $(IMAGE) -v "testing" --targets=arm.v6,amd64

publish-latest:
	@echo Version: $(VERSION) $(BUILD_DATE)
	seihon publish --dry-run=false --template docker/tmpl.Dockerfile --base-runtime-image alpine:$(ALPINE) \
	   --image-name $(IMAGE) -v "latest" --targets=$(TARGETS)

publish-images:
	@echo Version: $(VERSION) $(BUILD_DATE)
	seihon publish --dry-run=false --template docker/tmpl.Dockerfile --base-runtime-image alpine:$(ALPINE) \
	   --image-name $(IMAGE) -v "latest" -v "$(TAG_NAME)" --targets=$(TARGETS)
