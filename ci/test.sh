#!/bin/bash

set -e -x

pushd task_01_concourse
  bundle install
  bundle exec rspec
popd