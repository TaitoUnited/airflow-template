#!/bin/sh

###################################################################
# NOTE: Run CI/CD builds locally with command 'taito -r ci run:ENV'
###################################################################

BRANCH=$1     # e.g. dev, test, uat, stag, canary, or prod
IMAGE_TAG=$2  # e.g. commit SHA

set -e
export taito_mode=ci
export taito_ci_phases=
# Always build with local CI:
echo "export ci_exec_build=true" >> ./taito-config.sh

# Prepare build
taito build prepare:$BRANCH $IMAGE_TAG

# Prepare artifacts for deployment
# NOTE: Can be executed in parallel if no user input is required
taito artifact prepare:airflow:$BRANCH $IMAGE_TAG

# Deploy changes to target environment
# taito db deploy:$BRANCH
taito deployment deploy:$BRANCH $IMAGE_TAG

# Test and verify deployment
taito deployment wait:$BRANCH
# TODO: enable local ci tests
# taito test:$BRANCH
taito deployment verify:$BRANCH

# Release artifacts
# NOTE: Can be executed in parallel if no user input is required
taito artifact release:airflow:$BRANCH $IMAGE_TAG

# Release build
taito build release:$BRANCH

# TODO: revert on fail
