channel := Unstable
app_slug := "${REPLICATED_APP}"
version := "0.1.0-dev-${USER}"
release_notes := "CLI release by ${USER} on $(shell date)"
SHELL := /bin/bash -o pipefail

.PHONY: deps-vendor-cli
deps-vendor-cli:
	@if [[ -x deps/replicated ]]; then exit 0; else \
	echo '-> Downloading Replicated CLI... '; \
	mkdir -p deps/; \
	if [[ "`uname`" == "Linux" ]]; then curl -fsSL https://github.com/replicatedhq/replicated/releases/download/v0.19.0/replicated_0.19.0_linux_amd64.tar.gz | tar xvz -C deps; exit 0; fi; \
	if [[ "`uname`" == "Darwin" ]]; then curl -fsSL https://github.com/replicatedhq/replicated/releases/download/v0.19.0/replicated_0.19.0_darwin_amd64.tar.gz | tar xvz -C deps; exit 0; fi; fi;

.PHONY: lint
lint: check-api-token check-app deps-vendor-cli
	deps/replicated release lint --app $(app_slug) --yaml-dir manifests

.PHONY: check-api-token
check-api-token:
	@if [ -z "${REPLICATED_API_TOKEN}" ]; then echo "Missing REPLICATED_API_TOKEN"; exit 1; fi

.PHONY: check-app
check-app:
	@if [ -z "$(app_slug)" ]; then echo "Missing REPLICATED_APP"; exit 1; fi

.PHONY: list-releases
list-releases: check-api-token check-app deps-vendor-cli
	deps/replicated release ls --app $(app_slug)

.PHONY: release
release: check-api-token check-app deps-vendor-cli lint
	deps/replicated release create \
		--app $(app_slug) \
		--yaml-dir manifests \
		--promote $(channel) \
		--version $(version) \
		--release-notes $(release_notes) \
		--ensure-channel


# Use the current branch name for the channel name, 
# and use the git SHA for the release version, 
# adding a "-dirty" suffix to the version label if there are uncomitted changes
gitsha-release:
	@$(MAKE) release \
		channel=refs/heads/$(shell git rev-parse --abbrev-ref HEAD) \
		version=$(shell git rev-parse HEAD | head -c7)$(shell git diff --no-ext-diff --quiet --exit-code || echo -n "-dirty")
