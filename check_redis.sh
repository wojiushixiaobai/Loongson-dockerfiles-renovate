#!/bin/bash

CHECK_VERSION=${1:-?}

# github.com/docker-library/redis
GITHUB_OWNER=docker-library
GITHUB_REPO=redis
# library/redis
CR_OWNER=library
CR_REPO=${GITHUB_REPO}

APP_DIR=${CR_OWNER}/${CR_REPO}/${CHECK_VERSION}/debian

TMPDIR=$(mktemp -d)

if [ ! -d "${TMPDIR}" ]; then
    echo "Failed to create temporary directory"
    exit 1
fi

if [ -f "${TMPDIR}/Dockerfile" ]; then
    rm -f "${TMPDIR}/Dockerfile"
fi

DOCKERFILE_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/raw/master/${CHECK_VERSION}/debian/Dockerfile"
wget -qO "${TMPDIR}/Dockerfile" "${DOCKERFILE_URL}" || exit 1

function get_env_var() {
    grep -oP "ENV $1 \K.*" "${TMPDIR}/Dockerfile"
}

function check_app_version() {
    APP_VERSION=$1
    if [ ! -f "${APP_DIR}/Dockerfile" ]; then
        echo "No Dockerfile found for ${APP_DIR}"
        exit 1
    fi
    if grep -q "ENV REDIS_VERSION ${APP_VERSION}" "${TMPDIR}/Dockerfile"; then
        echo "latest"
    fi
}

REDIS_VERSION=$(get_env_var REDIS_VERSION)
CHECK_LATEST_VERSION=$(check_app_version ${REDIS_VERSION})

if [ "${CHECK_LATEST_VERSION}" == "latest" ]; then
    echo "Latest version already exists"
    exit 0
fi

ENV_VARS=("GOSU_VERSION" "REDIS_VERSION" "REDIS_DOWNLOAD_URL" "REDIS_DOWNLOAD_SHA")

for VAR in "${ENV_VARS[@]}"; do
    VALUE=$(get_env_var ${VAR})
    sed -i "s|ENV ${VAR} .*|ENV ${VAR} ${VALUE}|" "${APP_DIR}/Dockerfile"
done

sed -i 's|"versionInfo":".*",|"versionInfo":"'"${REDIS_VERSION}"'",|' "${APP_DIR}/Dockerfile"
sed -i "s|VERSION?=.*$|VERSION?=${REDIS_VERSION}|" "${APP_DIR}/../Makefile"