#!/bin/bash

set -e

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

function get_app_version() {
    grep -oP 'ENV PYTHON_VERSION \K.*' "${TMPDIR}/Dockerfile"
}

function get_gpg_key() {
    grep -oP 'ENV GPG_KEY \K.*' "${TMPDIR}/Dockerfile"
}

function get_pip_version() {
    grep -oP 'ENV PYTHON_PIP_VERSION \K.*' "${TMPDIR}/Dockerfile"
}

function get_setuptools_version() {
    grep -oP 'ENV PYTHON_SETUPTOOLS_VERSION \K.*' "${TMPDIR}/Dockerfile"
}

function get_pip_url() {
    grep -oP 'ENV PYTHON_GET_PIP_URL \K.*' "${TMPDIR}/Dockerfile"
}

function get_pip_sha() {
    grep -oP 'ENV PYTHON_GET_PIP_SHA256 \K.*' "${TMPDIR}/Dockerfile"
}

function check_app_version() {
    APP_VERSION=$1
    # dockerfiles/library/python/3.9/debian/Dockerfile
    if [ ! -f "${APP_DIR}/Dockerfile" ]; then
        echo "No Dockerfile found for ${APP_DIR}"
        exit 1
    fi
    if grep -q "ENV PYTHON_VERSION ${APP_VERSION}" "${TMPDIR}/Dockerfile"; then
        echo "latest"
    fi
}

PYTHON_VERSION=$(get_app_version)
CHECK_LATEST_VERSION=$(check_app_version ${PYTHON_VERSION})

if [ "${check_latest_version}" == "latest" ]; then
    echo "Latest version already exists"
    exit 0
fi

GPG_KEY=$(get_gpg_key)
PYTHON_PIP_VERSION=$(get_pip_version)
PYTHON_SETUPTOOLS_VERSION=$(get_setuptools_version)
PYTHON_GET_PIP_URL=$(get_pip_url)
PYTHON_GET_PIP_SHA256=$(get_pip_sha)

sed -i "s/ENV PYTHON_VERSION .*/ENV PYTHON_VERSION ${PYTHON_VERSION}/" "${APP_DIR}/Dockerfile"
sed -i "s/ENV GPG_KEY .*/ENV GPG_KEY ${GPG_KEY}/" "${APP_DIR}/Dockerfile"
sed -i "s/ENV PYTHON_PIP_VERSION .*/ENV PYTHON_PIP_VERSION ${PYTHON_PIP_VERSION}/" "${APP_DIR}/Dockerfile"
sed -i "s/ENV PYTHON_SETUPTOOLS_VERSION .*/ENV PYTHON_SETUPTOOLS_VERSION ${PYTHON_SETUPTOOLS_VERSION}/" "${APP_DIR}/Dockerfile"
sed -i "s/ENV PYTHON_GET_PIP_URL .*/ENV PYTHON_GET_PIP_URL ${PYTHON_GET_PIP_URL}/" "${APP_DIR}/Dockerfile"
sed -i "s/ENV PYTHON_GET_PIP_SHA256 .*/ENV PYTHON_GET_PIP_SHA256 ${PYTHON_GET_PIP_SHA256}/" "${APP_DIR}/Dockerfile"
sed -i "s/VERSION?=.*$/VERSION?=${PYTHON_VERSION}/" "${APP_DIR}/../Makefile"
