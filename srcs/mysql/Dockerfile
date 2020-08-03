FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk update
RUN apk add mysql mysql-client

RUN mkdir -p /run/mysqld

COPY my.cnf /etc/mysql/
COPY mysql-init /tmp/
COPY entrypoint.sh /tmp/

VOLUME ["/var/lib/mysql"]
EXPOSE 3306

ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]