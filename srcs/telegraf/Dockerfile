FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk add telegraf --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ENTRYPOINT ["/usr/bin/telegraf"]