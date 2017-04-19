#!/bin/bash

set -e -x

pushd task_01_concourse
cat > ~/.netrc <<EOF
  machine git.heroku.com
    login $HEROKU_EMAIL
    password $HEROKU_TOKEN
EOF
  git push https://git.heroku.com/task-01-concourse.git master:refs/heads/master
popd