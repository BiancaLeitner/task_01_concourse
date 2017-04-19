#!/bin/bash

set -e -x

pushd git-repository
  bundle install
  rspec
  brakeman
popd