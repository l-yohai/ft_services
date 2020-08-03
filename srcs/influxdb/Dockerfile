FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk update && apk add influxdb

EXPOSE 8086

ENTRYPOINT ["/usr/sbin/influxd"]