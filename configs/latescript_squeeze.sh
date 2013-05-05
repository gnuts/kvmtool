#!/bin/sh

SERVER=$1

mkdir /target/root/.ssh
cd /target/root/.ssh
wget "$SERVER/authorized_keys"
