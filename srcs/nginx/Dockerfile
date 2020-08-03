FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk update
RUN apk add nginx
RUN apk add openssh
RUN apk add openssl

COPY default.conf /etc/nginx/conf.d/
COPY entrypoint.sh /tmp/
COPY nginx.crt /etc/nginx/ssl/
COPY nginx.key /etc/nginx/ssl/

EXPOSE 80 443 22

ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]
