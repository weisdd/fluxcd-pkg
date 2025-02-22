#!/usr/bin/env bash

# This script runs e2e tests for pkg/git/gogit and pkg/git/libgit2.

set -o errexit

PROJECT_DIR=$(git rev-parse --show-toplevel)
DIR="$(cd "$(dirname "$0")" && pwd)"
GITLAB_CONTAINER=gitlab-flux-e2e

cd "${PROJECT_DIR}/git/libgit2" && make libgit2
LIBGIT2_BUILD_DIR=${PROJECT_DIR}/git/libgit2/build . "${PROJECT_DIR}/git/libgit2/libgit2-vars.env"

if [[ "${GO_TEST_PREFIX}" = "" ]] || [[ "${GO_TEST_PREFIX}" = *"TestGitLabCEE2E"* ]]; then
    # Cleanup gitlab container if persistence is not enabled.
    if [[ -z "${PERSIST_GITLAB}" ]]; then
        trap "docker kill ${GITLAB_CONTAINER} && docker rm ${GITLAB_CONTAINER}" EXIT
    fi
    source "${DIR}/setup_gitlab.sh"
fi

cd "${DIR}"
CGO_LDFLAGS=$(PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --libs --static --cflags libgit2)
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" CGO_LDFLAGS="${CGO_LDFLAGS}" CGO_ENABLED=1 \
    go test -v -tags 'netgo,osusergo,static_build,e2e' -race -run "^${GO_TEST_PREFIX}.*" ./...
