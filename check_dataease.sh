#!/bin/bash

CHECK_VERSION=${1:-latest}

# github.com/wojiushixiaobai/dataease
GITHUB_OWNER=wojiushixiaobai
GITHUB_REPO=dataease
# dataease/dataease
CR_OWNER=dataease
CR_REPO=${GITHUB_REPO}

APP_DIR=${CR_OWNER}/${CR_REPO}/openjdk-17-slim-buster

TMPDIR=$(mktemp -d)

if [ ! -d "${TMPDIR}" ]; then
    echo "Failed to create temporary directory"
    exit 1
fi

function get_app_version() {
    curl -s "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/${CHECK_VERSION}" | jq -r '.tag_name'
}

function check_app_version() {
    APP_VERSION=$1
    if [ ! -f "${APP_DIR}/Dockerfile" ]; then
        echo "No Dockerfile found for ${APP_DIR}"
        exit 1
    fi
    if grep -q "ARG VERSION=${APP_VERSION}" "${APP_DIR}/Dockerfile"; then
        echo "latest"
    fi
}

APP_VERSION=$(get_app_version)
CHECK_LATEST_VERSION=$(check_app_version ${APP_VERSION})

if [ "${CHECK_LATEST_VERSION}" == "latest" ]; then
    echo "Latest version already exists"
    exit 0
fi

sed -i "s|ARG VERSION=.*|ARG VERSION=${APP_VERSION}|" "${APP_DIR}/Dockerfile"
sed -i "s|VERSION?=.*$|VERSION?=${APP_VERSION}|" "${APP_DIR}/Makefile"