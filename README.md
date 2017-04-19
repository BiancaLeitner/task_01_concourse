# Task 1 - Michael Raidel
* create a Rails app with scaffold for CRUD resource
* test the create part in a concourse job with Capybara
* use brakeman to check the app in a concourse job (it should fail if there are any warnings)
* bonus: test if there are more brakeman warnings than in the previous commit.

## Table of contents
[__1. Create a Docker Machine__ 🛠](#docker-machine)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.1 List available machines](#list-machines)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.2 Create a new machine](#create-machine)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.3 Set the environment commands for your new machine](#set-env)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.4 Start and stop machines](#start-stop)

[__2. Setup Concourse for the 1st time__ 🛠](#setup-concourse)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[2.1 Setup docker-compose for Concourse](#setup-docker-compose)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[2.2 Build, (re)create, start, and attach to containers for a service - spin everything up](#spin-up)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[2.3 Setup the Fly-CLI tool](#setup-fly)

[__3. Start Concourse after Setup__ 🏁](#start-concourse)

[__4. Create Test with Capybara and RSpec__ 🐹](#capybara)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[4.1 Install Capybara and RSpec](#install)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[4.2 Set up Test for create-Action](#setup-test)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[4.3 Run the test](#run-test)

[__5. Add Brakeman__ 👾](#brakeman)


[__6. Build a Concourse Pipeline__ 🛠](#build-pipeline)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[6.1 Create files for commit-stage (run unit tests in Concourse)](#run-tests)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[6.2 Create files for deploy-stage](#deploy-stage)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[6.2 Create files for deploy-stage](#deploy-stage)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[6.3 Configure app for Heroku deployment](#heroku)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[6.4 Create a pipeline (wrap everything up)](#start-pipeline)

## 1. <a name="docker-machine"></a> Create a Docker Machine 🛠
>Note: Pre-Requirements: Docker Engine and Docker Compose are installed

### 1.1 <a name="list-machines"></a> List available machines 
```shell
$ docker-machine ls
```

*output*:
```shell
 NAME   ACTIVE   DRIVER   STATE   URL   SWARM   DOCKER   ERRORS
```

### 1.2 <a name="create-machine"></a> Create a new machine
```shell
$ docker-machine create --driver=virtualbox default
```

check if machine was created:
```shell
$ docker-machine ls
```

*output*:
```shell
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
default   -        virtualbox   Running   tcp://192.168.99.100:2376           v17.04.0-ce
```

### 1.3 <a name="set-env"></a> Set the environment commands for your new machine
```shell
$ docker-machine env default
```

*output*:
```shell
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/Bee/.docker/machine/machines/default"
export DOCKER_MACHINE_NAME="default"
# Run this command to configure your shell:
# eval $(docker-machine env default)
```

connect your shell to the new machine
```shell
$ eval $(docker-machine env default)
```

### 1.4 <a name="start-stop"></a> Start and stop machines

```shell
$ docker-machine stop default
$ docker-machine start default
```

## 2. <a name="setup-concourse"></a> Setup Concourse for the 1st time 🛠
>Note: find the complete installation-guide <a href="https://concourse.ci/docker-repository.html" target="_blank">here</a>

### 2.1 <a name="setup-docker-compose"></a> Setup docker-compose for Concourse

create a __docker-compose.yml__ file in your project root and add the following to the file:
```yaml
concourse-db:
  image: postgres:9.5
  environment:
    POSTGRES_DB: concourse
    POSTGRES_USER: concourse
    POSTGRES_PASSWORD: changeme
    PGDATA: /database

concourse-web:
  image: concourse/concourse
  links: [concourse-db]
  command: web
  ports: ["8080:8080"]
  volumes: ["./keys/web:/concourse-keys"]
  environment:
    CONCOURSE_BASIC_AUTH_USERNAME: concourse
    CONCOURSE_BASIC_AUTH_PASSWORD: changeme
    CONCOURSE_EXTERNAL_URL: "${CONCOURSE_EXTERNAL_URL}"
    CONCOURSE_POSTGRES_DATA_SOURCE: |-
      postgres://concourse:changeme@concourse-db:5432/concourse?sslmode=disable

concourse-worker:
  image: concourse/concourse
  privileged: true
  links: [concourse-web]
  command: worker
  volumes: ["./keys/worker:/concourse-keys"]
  environment:
    CONCOURSE_TSA_HOST: concourse-web
```

run the following to generate the necessary keys:
```shell
$ mkdir -p keys/web keys/worker

$ ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
$ ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''

$ ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''

$ cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
$ cp ./keys/web/tsa_host_key.pub ./keys/worker
```

get ip of your docker-machine:
```shell
$ docker-machine ip default
```

*output*:
```shell
192.168.99.100
```

set CONCOURSE_EXTERNAL_URL to whatever your docker-machine's IP is, for example:
```shell
$ export CONCOURSE_EXTERNAL_URL=http://192.168.99.100:8080
```

### 2.2 <a name="spin-up"></a> Build, (re)create, start, and attach to containers for a service - spin everything up

```shell
$ docker-compose up
```

* browse to your configured external URL, in our case <a href="http://192.168.99.100:8080/" target="_blank">192.168.99.100:8080</a>
* log in with the username _concourse_ and password _changeme_.


### 2.3 <a name="setup-fly"></a> Setup the Fly-CLI tool
>Note: a list of all available Fly-Cli commands can be found [here!](https://concourse.ci/fly-cli.html)

* click to download the Fly-CLI appropriate for your operating system

* copy the fly binary into your path ($PATH), such as /usr/local/bin or ~/bin. 
<br/>Don't forget to also make it executable:
```shell
$ sudo mkdir -p /usr/local/bin
$ sudo mv ~/Downloads/fly /usr/local/bin
$ sudo chmod 0755 /usr/local/bin/fly
```

## 3. <a name="start-concourse"></a> Start Concourse after Setup 🏁

start your Docker Machine
```shell
$ docker-machine start <name-of-your-machine>
```

set environment variables of your machine
```shell
$ docker-machine env <name-of-your-machine>
```

execute each of those export commands
```shell
$ eval $(docker-machine env <name-of-your-machine>)
```

get IP of your docker-machine
```shell
$ docker-machine ip <name-of-your-machine>
```

set CONCOURSE_EXTERNAL_URL to whatever your docker-machine's IP is
```shell
$ export CONCOURSE_EXTERNAL_URL=http://<your-machines-ip>:8080
```

build, (re)create, start, and attach to containers for a service - spin everything up
```shell
$ docker-compose up
```
--> browse to your configured external URL - Concourse is up and running 😀

## 4. <a name="capybara"></a> Create Test with Capybara and RSpec 🐹

### 4.1 <a name="install"></a> Install Capybara and RSpec

add this to your Gemfile:
```ruby
group :development, :test do
  gem 'rspec-rails', '~> 3.0'
end
 
group :test do
  gem 'capybara'
end
```

run:
```shell
$ bundle install
$ rails generate rspec:install
```
> Note: The second command should create spec/spec_helper.rb and spec/rails_helper.rb files.

add following to spec/rails_helper.rb:
```ruby
$ require 'capybara/rails'
```

### 4.2 <a name="setup-test"></a> Set up Test for create-Action

The feature we will be testing is the create-Action of our app (= adding new articles to the blog).

start by defining a scenario for this feature's test:
```ruby
# 1. Go to root path (there will be a button to add a new article)
# 2. Click on the "New article" button
# 3. Fill out the form
# 4. Submit the form
# 5. See the 'show' page of created article
```

create a new folder __spec/articles__ and a new file __spec/articles/creating_article_spec.rb__ and add the following to the file:
```ruby
require 'rails_helper.rb'

feature 'Creating article' do
  scenario 'can create an article' do
    # 1. Go to root path (there will be a button to add a new article)
    visit '/'
    # 2. Click on the "New article" button
    click_link 'New article'
    # 3. Fill out the form - add a title  with at least 5 characters and a text with at least 100 characters
    fill_in 'Title', :with => 'Lorem'
    fill_in 'Text', :with => 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut l'
    # 4. Submit the form
    click_button 'Create Article'
    # 5. See the 'show' page of created article
    expect(page).to have_content('Lorem ipsum dolor sit amet')
  end
end
```

### 4.3 <a name="run-test"></a> Run the test
```shell
$ rspec spec/articles/creating_article_spec.rb
```

*output:*
```shell
.

Finished in 0.40847 seconds (files took 4.21 seconds to load)
1 example, 0 failures
```

## 5. <a name="brakeman"></a> Add Brakeman

Add Brakeman to your Gemfile:
```ruby
group :development do
  gem 'brakeman', :require => false
end
```

Test if it works - run:
```shell
$ brakeman
```

*output*
```shell
+SUMMARY+

+-------------------+-------+
| Scanned/Reported  | Total |
+-------------------+-------+
| Controllers       | 4     |
| Models            | 3     |
| Templates         | 10    |
| Errors            | 0     |
| Security Warnings | 0 (0) |
+-------------------+-------+
```

## 6. <a name="build-pipeline"></a> Build a Concourse Pipeline 🛠

target and log in to Concourse (with username and Password defined in docker-compose.yml)
```shell
$ fly -t ci login -c <your concourse URL>
```
> Explanation: The -t flag is the name we'll use to refer to this instance in the future. The -c flag is the concourse URL that we'd like to target.

*output*
```shell
target saved
```

### 6.1 <a name="run-tests"></a> Create files for commit-stage (run unit tests in Concourse)

create a new folder __ci__ and a new __ci/commit_build.yml__ file and add the following to the file:
```yml
# run task on a Linux worker
platform: linux

# declare the image to use for the task's container
image_resource:
  type: docker-image
  source:
    repository: ruby
    tag: 2.3.3

# define a set of things that we need in order for our task to run
inputs:
# ... in this case blog source code in order to run tests on it
- name: task_01_concourse

# define how concourse should run the test
run:
  path: ./task_01_concourse/ci/test.sh
```

create a new __ci/test.sh__ file and add the following to the file:

```sh
#!/bin/bash

set -e -x

pushd task_01_concourse
  bundle install
  rspec
  brakeman
popd
```
> Explanation: The #!/bin/bash is a shebang line that tells the operating system that when we execute this file we should run it using the /bin/bash interpreter. The set -e -x line is setting a few bash options. Namely, -e make it so the entire script fails if a single command fails (which is generally desirable in CI). By default, a script will keep executing if something fails. The -x means that each command should be printed as it's run (also desirable in CI).

make test.sh executable
```shell
$ chmod +x ci/test.sh
```

execute the commit_build task (run unit tests inside Concourse)
```shell
$ fly -t ci execute -c ci/commit_build.yml
```

*output*
```shell
+ rspec
.

Finished in 0.3907 seconds (files took 1.91 seconds to load)
1 example, 0 failures
.
.
.
+ brakeman
.
.
.
+SUMMARY+

+-------------------+-------+
| Scanned/Reported  | Total |
+-------------------+-------+
| Controllers       | 4     |
| Models            | 3     |
| Templates         | 10    |
| Errors            | 0     |
| Security Warnings | 0 (0) |
+-------------------+-------+



+ popd
/tmp/build/e55deab7
succeeded
```

### 6.2 <a name="deploy-stage"></a> Create files for deploy-stage (deploy app to Heroku)

create a new __ci/deploy_build.yml__ file and add the following to the file:
```yml
platform: linux

image_resource:
  type: docker-image
  source:
    repository: concourse/bosh-cli

inputs:
- name: git-repository

run:
  path: git-repository/ci/deploy.sh
```

create a new __ci/deploy.sh__ file and add the following to the file:
```shell
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
```

make test.sh executable
```shell
$ chmod +x ci/deploy.sh
```

create a new __ci/credentials.yml__ file and add the following to the file:
```yml
heroku_email: your-heroku-email
heroku_token: your-heroku-token
```
>Note: You can find a token to use on the “Account” page (in the “API Key” section) on your dashboard

### 6.3 <a name="heroku"></a> Configure app for Heroku deployment

Heroku requires postgres instead of sqlite3 - if you created your Rails-App with sqlite3, you have to add the following to your Gemfile:
```ruby
group :production do
  gem 'pg'
end
```
>Explanation: Now postgres will be used for production!

Heroku throws a warning if you did not specify the ruby-version in your Gemfile, if you didn't do that already add:
```ruby
ruby '2.3.3'
```
>Note: The ruby-version has to match the version you are using, otherwise an error will be thrown!

Heroku requires a so called Procfile (= a mechanism for declaring what commands are run by your application’s dynos on the Heroku platform). Create a file named "Procfile" in your root directory and add:
```Procfile
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-production}
```

Now create a Dockerfile in your root directory and add the following:
```Dockerfile
FROM ruby:2.3.3
RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs
RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list \
         && apt-get update \
         && apt-get install -y git \
         && apt-get clean all

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile* /usr/src/app/

RUN gem install bundler
RUN bundle install

COPY . /usr/src/app

RUN RAILS_ENV=production

CMD ["bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0"]
```

After the app was successfully deployed to Heroku, we have to migrate the db, in order to be able to do that we need to add the heroku-repository as remote repository:
```shell
$ heroku git:remote -a <name-of-your-heroku-app>
```
>Note: You need to have the <a href="https://devcenter.heroku.com/articles/heroku-cli" target="_blank">Heroku Cli </a>installed on your system.

### 6.4 <a name="start-pipeline"></a> Create a pipeline (wrap everything up

create a __ci/pipeline.yml__ file and add the following to the file:
```yml
---
resources:
  - name: git-repository
    type: git
    source:
      uri: "https://github.com/BiancaLeitner/task_01_concourse.git"

jobs:
- name: commit-stage
  plan:
  - get: git-repository
    trigger: true
  - task: run-tests
    file: git-repository/ci/commit_build.yml
   
- name: deploy-stage
  serial: true
  plan:
  - get: git-repository
    trigger: true
    passed: [commit-stage]
  - task: deploy-heroku
    params:
      HEROKU_EMAIL: {{heroku_email}}
      HEROKU_TOKEN: {{heroku_token}}
    file: git-repository/ci/deploy_build.yml
```
>Explanation: Pipelines are built up from resources and jobs. Resources are external, versioned things such as Git repositories or S3 buckets and jobs are a grouping of resources and tasks that actually do the work in the system.

upload the pipeline:
```shell
$ fly set-pipeline -t ci -p ci-pipe -c ci/pipeline.yml --load-vars-from ci/credentials.yml
```

*output*
```shell
resources:
  resource git-repository has been added:
    name: git-repository
    type: git
    source:
      uri: https://github.com/BiancaLeitner/task_01_concourse.git

jobs:
  job commit-stage has been added:
    name: commit-stage
    plan:
    - get: git-repository
      trigger: true
    - task: run-tests
      file: git-repository/ci/commit_build.yml

  job deploy-stage has been added:
    name: deploy-stage
    serial: true
    plan:
    - get: git-repository
      passed:
      - commit-stage
      trigger: true
    - task: deploy-heroku
      file: git-repository/ci/deploy_build.yml
      params:
        HEROKU_EMAIL: <here-is-your-heroku-email>
        HEROKU_TOKEN: <here-is-your-heroku-token>
      
apply configuration? [yN]:
```
--> answer with y

*output*
```shell
pipeline created!
you can view your pipeline here: http://192.168.99.100:8080/teams/main/pipelines/ci-pipe

the pipeline is currently paused. to unpause, either:
  - run the unpause-pipeline command
  - click play next to the pipeline in the web ui
```
>Note: If you are not yet logged in the Concourse-Web-UI do so - otherwise you won't be able to see the pipeline!

When the app was successfully deployed to Heroku, we have to install the db:
```shell
$ heroku run rake db:migrate
```

__THE END - Cheers__ 🍺