#!/bin/bash

set -e -x

pushd blog
  bundle install
  bundle exec rspec
popd