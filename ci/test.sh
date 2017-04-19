#!/bin/bash

set -e -x

pushd task_01_concourse
  bundle install
  bundle exec rspec
  bundle exec brakeman -o brakeman_output.json
  git checkout -b brakeman
  git push -u origin brakeman
  git checkout master
  git checkout brakeman -- brakeman_output.json
  brakeman --compare brakeman_output.json
popd