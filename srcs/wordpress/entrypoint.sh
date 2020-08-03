#!/bin/sh

sleep 5
sh /tmp/launch-wordpress.sh
php -S 0.0.0.0:5050 -t /etc/wordpress/
until [ $? != 1 ]
do
	php -S 0.0.0.0:5050 -t /etc/wordpress/
done