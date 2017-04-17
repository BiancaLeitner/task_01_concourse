# Test the create part in a concourse job with capybara

## Table of contents
1. [Create a Docker Machine 🔨](#docker-machine)
    <br/> 1.1 [List available machines](#list-machines)
    <br/> 1.2 [Create a new machine](#create-machine)
    <br/> 1.3 [Get the environment commands for your new VM](#get-env)
    <br/> 1.4 [Connect your shell to the new machine](#connect-shell)
    <br/> 1.5 [Start and stop machines](#start-stop)
2. [Setup Concourse for the 1st time 🛠](#setup-concourse)
  <br/> 2.1 [Create a docker-compose.yml file in your project root](#create-docker-yml)
  <br/> 2.2 [Build, (re)create, start, and attach to containers for a service - spin everything up](#spin-up1)
  <br/> 2.3 [Setup the fly-CLI tool](#setup-fly)
3. [Start Concourse after Setup 🏁](#start-concourse)
 <br/> 3.1 [Start your Docker Machine](#start-machine)
 <br/> 3.2 [Set environment variables of your machine](#set-env)
 <br/> 3.3 [Set CONCOURSE_EXTERNAL_URL to whatever your docker-machine's IP is](#set-ip)
 <br/> 3.4 [Build, (re)create, start, and attach to containers for a service - spin everything up](#spin-up2)


## 1. <a name="docker-machine"></a> Create a Docker Machine 
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

__check if machine was created:__
```shell
$ docker-machine ls
```

*output*:
```shell
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
default   -        virtualbox   Running   tcp://192.168.99.100:2376           v17.04.0-ce
```

### 1.3 <a name="get-env"></a> Get the environment commands for your new VM

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

### 1.4 <a name="connect-shell"></a> Connect your shell to the new machine

```shell
$ eval "$(docker-machine env default)"
```

### 1.5 <a name="start-stop"></a> Start and stop machines

```shell
$ docker-machine stop default
$ docker-machine start default
```

## 2. <a name="setup-concourse"></a> Setup Concourse for the 1st time
>Note: find the complete installation-guide <a href="https://concourse.ci/docker-repository.html" target="_blank">here</a>

### 2.1 <a name="create-docker-yml"></a> Create a docker-compose.yml file in your project root

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

__run the following to generate the necessary keys:__
```shell
$ mkdir -p keys/web keys/worker

$ ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
$ ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''

$ ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''

$ cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
$ cp ./keys/web/tsa_host_key.pub ./keys/worker
```

__get ip of your docker-machine:__
```shell
$ docker-machine ip default
```

*output*:
```shell
192.168.99.100
```

__set CONCOURSE_EXTERNAL_URL to whatever your docker-machine's IP is, for example:__
```shell
$ export CONCOURSE_EXTERNAL_URL=http://192.168.99.100:8080
```

### 2.2 <a name="spin-up1"></a> Build, (re)create, start, and attach to containers for a service - spin everything up

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

## 3. <a name="start-concourse"></a> Start Concourse after Setup

### 3.1 <a name="start-machine"></a> Start your Docker Machine
```shell
$ docker-machine start <name-of-your-machine>
```

### 3.2 <a name="set-env"></a> Set environment variables of your machine
```shell
$ docker-machine env <name-of-your-machine>
```

*output*
```shell
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/Bee/.docker/machine/machines/default"
export DOCKER_MACHINE_NAME="default"
# Run this command to configure your shell:
# eval $(docker-machine env default)
```

__execute each of those export commands__
```shell
$ eval "$(docker-machine env <name-of-your-machine>)"
```

### 3.4 <a name="set-ip"></a> Set CONCOURSE_EXTERNAL_URL to whatever your docker-machine's IP is
__Get IP of your docker-machine__
```shell
$ docker-machine ip <name-of-your-machine>
```

__set IP__
```shell
$ export CONCOURSE_EXTERNAL_URL=http://<your-machines-ip>:8080
```

### 3.4 <a name="spin-up2"></a> Build, (re)create, start, and attach to containers for a service - spin everything up
```shell
$ docker-compose up
```
--> browse to your configured external URL - Concourse is up and running 😀