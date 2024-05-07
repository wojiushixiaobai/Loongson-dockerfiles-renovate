#!/bin/bash

CHECK_VERSION=${1:-?}

# github.com/docker-library/python
GITHUB_OWNER=docker-library
GITHUB_REPO=python
# library/python
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

DOCKERFILE_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/raw/master/${CHECK_VERSION}/slim-bullseye/Dockerfile"
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
    if grep -q "ENV PYTHON_VERSION ${APP_VERSION}" "${TMPDIR}/Dockerfile"; then
        echo "latest"
    fi
}

PYTHON_VERSION=$(get_env_var PYTHON_VERSION)
CHECK_LATEST_VERSION=$(check_app_version ${PYTHON_VERSION})

if [ "${CHECK_LATEST_VERSION}" == "latest" ]; then
    echo "Latest version already exists"
    exit 0
fi

ENV_VARS=("PYTHON_VERSION" "GPG_KEY" "PYTHON_PIP_VERSION" "PYTHON_SETUPTOOLS_VERSION" "PYTHON_GET_PIP_URL" "PYTHON_GET_PIP_SHA256")

for VAR in "${ENV_VARS[@]}"; do
    VALUE=$(get_env_var ${VAR})
    sed -i "s|ENV ${VAR} .*|ENV ${VAR} ${VALUE}|" "${APP_DIR}/Dockerfile"
done

sed -i "s|VERSION?=.*$|VERSION?=${PYTHON_VERSION}|" "${APP_DIR}/../Makefile"