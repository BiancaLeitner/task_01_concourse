# Task 1 - Markus Raidel
* create a Rails app with scaffold for CRUD resource
* test the create part in a concourse job with Capybara
* use brakeman to check the app in a concourse job (it should fail if there are any warnings)
* bonus: test if there are more brakeman warnings than in the previous commit.

## Table of contents
[__1. Create a Docker Machine__ 🔨](#docker-machine)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.1 List available machines](#list-machines)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.2 Create a new machine](#create-machine)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.3 Set the environment commands for your new machine](#set-env)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[1.4 Start and stop machines](#start-stop)

[__2. Setup Concourse for the 1st time__ 🛠](#setup-concourse)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[2.1 Setup docker-compose for concourse](#setup-docker-compose)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[2.2 Build, (re)create, start, and attach to containers for a service - spin everything up](#spin-up)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[2.3 Setup the fly-CLI tool](#setup-fly)

[__3. Start Concourse after Setup__ 🏁](#start-concourse)

[__4. Create Test with Capybara and RSpec__ 🐹](#capybara)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[4.1 Install Capybara and RSpec](#install)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[4.2 Set up Test for create-Action](#setup-test)
  <br/>&nbsp;&nbsp;&nbsp;&nbsp;[4.3 Run the test](#run-test)


## 1. <a name="docker-machine"></a> Create a Docker Machine 🔨
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

Connect your shell to the new machine
```shell
$ eval "$(docker-machine env default)"
```

### 1.4 <a name="start-stop"></a> Start and stop machines

```shell
$ docker-machine stop default
$ docker-machine start default
```

## 2. <a name="setup-concourse"></a> Setup Concourse for the 1st time 🛠
>Note: find the complete installation-guide <a href="https://concourse.ci/docker-repository.html" target="_blank">here</a>

### 2.1 <a name="setup-docker-compose"></a> Setup docker-compose for Concourse

Create a docker-compose.yml file in your project root:
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


### <a name="setup-fly"></a> 2.3 Setup the fly-CLI tool

* click to download the fly CLI appropriate for your operating system

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
$ eval "$(docker-machine env <name-of-your-machine>)"
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

Add following to spec/rails_helper.rb:
```ruby
$ require 'capybara/rails'
```

### 4.2 <a name="setup-test"></a> Set up Test for create-Action

The feature we will be testing is the create-Action of our app (= adding new articles to the blog).

Start by defining a scenario for this feature's test:
```ruby
# 1. Go to root path (there will be a button to add a new article)
# 2. Click on the "New article" button
# 3. Fill out the form
# 4. Submit the form
# 5. See the 'show' page of created article
```

Create a new folder __spec/articles__ and a new file __spec/articles/creating_article_spec.rb__ and add the following to the file:
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