#!/bin/sh

/usr/bin/mysql_install_db --user=root
/usr/bin/mysqld --user=root --bootstrap --verbose=0 < /tmp/mysql-init
/usr/bin/mysqld --user=root --console