#!/usr/bin/env bash
$DOCKER_COMPOSE_VERSION = "1.2.2"

echo "-- Updating the system..."
apt update

echo "-- Installing docker pre-requisites..."
apt install -y curl apt-transport-https ca-certificates software-properties-common

echo "-- Installing docker-ce..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
apt update
apt install -y docker-ce

echo "Installing docker-compose..."
curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose

echo "Installing git..."
apt install -y git
