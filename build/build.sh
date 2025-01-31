#!/bin/bash

set -ex

# https://apple.stackexchange.com/questions/83939/compare-multi-digit-version-numbers-in-bash/123408#123408
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

DOCKER_IMAGE="lambci/lambda:build-python"
PKG_DIR="python"
PYTHON_VERSION=${1:-3.8}
PACKAGE_VERSION=$PYTHON_VERSION
PIP="pip"
ARCHITECTURE=${2:-"arm64"}
DOCKER_SUFFIX=""

rm -rf ${PKG_DIR} && mkdir -p ${PKG_DIR}

if [ $(version $PYTHON_VERSION) -ge $(version "3.9") ]; then
    DOCKER_IMAGE="public.ecr.aws/sam/build-python3.9:1.83.0"
    PIP="pip3"
    DOCKER_SUFFIX="-x86_64"
fi
if [ $(version $PYTHON_VERSION) -ge $(version "3.10") ]; then
    # DOCKER_IMAGE="public.ecr.aws/sam/build-python3.10:1.83.0"
    DOCKER_IMAGE="public.ecr.aws/sam/build-python3.10:latest"
    # DOCKER_IMAGE="public.ecr.aws/lambda/python:3.10"
    PIP="pip3"
    DOCKER_SUFFIX="-$ARCHITECTURE"
fi
if [ $(version $PYTHON_VERSION) -ge $(version "3.11") ]; then
    DOCKER_IMAGE="public.ecr.aws/sam/build-python3.11:latest"
    PIP="pip3"
    DOCKER_SUFFIX="-$ARCHITECTURE"
fi
if [ $(version $PYTHON_VERSION) -ge $(version "3.12") ]; then
    DOCKER_IMAGE="public.ecr.aws/sam/build-python3.12:latest"
    PIP="pip3"
    DOCKER_SUFFIX="-$ARCHITECTURE"
fi

# docker run -v $(pwd):/var/task ${DOCKER_IMAGE}${DOCKER_SUFFIX} \
# yum install -y mysql-devel && \
docker run -v $(pwd):/var/task ${DOCKER_IMAGE}${DOCKER_SUFFIX} \
    ${PIP} install -U pip setuptools wheel setuptools-rust && \
    ${PIP} install \
        --platform manylinux2014_aarch64 \
        --target ${PKG_DIR} \
        --implementation cp \
        --python-version 3.10 \
        --only-binary=:all: --upgrade \
        -r requirements.txt

# rm -rf ./python/*.dist-info
# find ./python/ -name "tests" -type d | xargs -I{} rm -rf {}
# find ./python/ -name "docs" -type d | xargs -I{} rm -rf {}
# find ./python/ -name "__pycache__" -type d | xargs -I{} rm -rf {}
# rm -rf ./python/boto*

zip -r releases/aws-lambda-layer-${PACKAGE_VERSION}${DOCKER_SUFFIX}.zip python