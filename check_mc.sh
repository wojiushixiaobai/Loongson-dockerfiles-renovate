#!/bin/bash

CHECK_VERSION=${1:-debian}

# github.com/minio/mc
GITHUB_OWNER=minio
GITHUB_REPO=mc
# minio/mc
CR_OWNER=${GITHUB_OWNER}
CR_REPO=${GITHUB_REPO}

APP_DIR=${CR_OWNER}/${CR_REPO}/${CHECK_VERSION}

TMPDIR=$(mktemp -d)

if [ ! -d "${TMPDIR}" ]; then
    echo "Failed to create temporary directory"
    exit 1
fi

if [ -f "${TMPDIR}/Dockerfile" ]; then
    rm -f "${TMPDIR}/Dockerfile"
fi

DOCKERFILE_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/raw/master/Dockerfile"
wget -qO "${TMPDIR}/Dockerfile" "${DOCKERFILE_URL}" || exit 1

function get_go_version() {
    cat "${TMPDIR}/Dockerfile" | grep -oP 'FROM golang:\K[0-9.]+'
}

function get_mc_version() {
    curl -s "https://api.github.com/repos/${GITHUB_OWNER}/mc/releases/latest" | jq -r '.tag_name'
}

function check_app_version() {
    APP_VERSION=$1
    if [ ! -f "${APP_DIR}/Dockerfile" ]; then
        echo "No Dockerfile found for ${APP_DIR}"
        exit 1
    fi
    if grep -q "ARG MC_VERSION=${APP_VERSION}" "${TMPDIR}/Dockerfile"; then
        echo "latest"
    fi
}

MC_VERSION=$(get_mc_version)

CHECK_LATEST_VERSION=$(check_app_version ${MC_VERSION})

if [ "${CHECK_LATEST_VERSION}" == "latest" ]; then
    echo "Latest version already exists"
    exit 0
fi

GO_VERSION=$(get_go_version)
ENV_VARS=("MC_VERSION")

for VAR in "${ENV_VARS[@]}"; do
    VALUE=${!VAR}
    sed -i "s|ARG ${VAR}=.*|ARG ${VAR}=${VALUE}|" "${APP_DIR}/Dockerfile"
done

sed -i "s|cr.loongnix.cn/library/golang:.*-buster|cr.loongnix.cn/library/golang:${GO_VERSION}-buster|" "${APP_DIR}/Dockerfile"
sed -i "s|MC_VERSION?=.*$|MC_VERSION?=${MC_VERSION}|" "${APP_DIR}/Makefile"