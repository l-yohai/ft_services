#!/bin/bash

mkdir -p /var/run/nginx

ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
adduser --disabled-password admin
echo "admin:admin" | chpasswd

/usr/sbin/sshd

nginx -g "daemon off;"
