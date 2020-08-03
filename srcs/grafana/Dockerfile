FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk add grafana --repository=http://dl-3.alpinelinux.org/alpine/edge/testing/

COPY conf/provisioning/datasources/influxdb.yaml /usr/share/grafana/conf/provisioning/datasources/
COPY conf/provisioning/dashboards/dashboards.yaml /usr/share/grafana/conf/provisioning/dashboards/
COPY dashboards /var/lib/grafana/dashboards/

EXPOSE 3000

ENTRYPOINT ["/usr/sbin/grafana-server", "--config=/etc/grafana/grafana.ini", "--homepath=/usr/share/grafana"]