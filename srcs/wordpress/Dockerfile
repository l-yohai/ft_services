FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk update
RUN apk add php7 php7-fpm php7-opcache php7-gd php7-mysqli php7-zlib\
			php7-curl php7-mbstring php7-json php7-session mysql-client

RUN wget https://wordpress.org/latest.tar.gz
RUN tar -xvf latest.tar.gz
RUN rm -f latest.tar.gz
RUN mv wordpress /etc/

COPY wp-config.php /etc/wordpress/
COPY wordpress.sql /tmp/
COPY launch-wordpress.sh /tmp/
COPY entrypoint.sh /tmp/

EXPOSE 5050
ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]