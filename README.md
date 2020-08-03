# ft_services
---
### settings
- 클러스터에서 42툴박스를 이용하여 도커를 goinfre로 옮기고, 용량문제로 인해, minikube 역시 goinfre로 옮겨준다.
- virtualbox를 이용하여 minikube start
- minikube 노드 안에서 도커 이미지를 사용하기 위하여 docker-env 명령어를 이용한다.
```shell
# init docker
./42toolbox/init_docker.sh
# start minikube
mv .minikube goinfre/minikube
ln -s goinfre/minikube .minikube
minikube delete
minikube start --driver=virtualbox
eval $(minikube -p minikube docker-env)
# start ft_services
./srcs/setup.sh
```
---
#### 이미지 빌드 시 ENTRYPOINT와 CMD의 차이
https://bluese05.tistory.com/77

도커파일 마지막에 ENTRYPOINT로 이미지를 빌드해놓은 경우에 pkill을 했을 때 자동으로 재시작 됨.

내 파일에서 mysql <-> ftps의 차이가 여기서 나타남.
mysqld를 kill한 경우 자동으로 재시작 되지만 vsftpd를 kill한 경우 자동으로 재시작 되지 않는다.
* nginx는 ENTRYPOINT로 이미지를 빌드하지만 (nginx -g "daemon off";) /usr/sbin/sshd의 경우는 살짝 다름. nginx 서버를 kill하면 자동으로 재시작 되지만, sshd 서버를 kill한 경우에는 자동으로 재시작 되지 않는다.

CMD를 사용한 경우에는 yaml파일에서 livenessprobe를 사용해야 헬스체크와 진단을 할 수 있다.

```Shell
kubectl exec deploy/nginx-deployment -- pkill sshd
kubectl exec deploy/mysql-deployment -- pkill mysqld
kubectl exec deploy/ftps-deployment -- pkill vsftpd
kubectl exec deploy/influxdb-deployment -- pkill influxd
```

---
### nginx with docker
```shell
# build nginx image
docker run -it -p 80:80 -p 443:443 alpine
# update and import modules
/ \# apk update && apk add nginx openssh openssl
# create certification and key
/ \# mkdir -p /etc/nginx/ssl
/ \# openssl req -newkey rsa:4096 -x509 -days 365 -nodes \
			-out /etc/nginx/ssl/nginx.crt \
			-keyout /etc/nginx/ssl/nginx.key \
			-subj "/C=KR/ST=SEOUL/L=SEOUL/O=42SEOUL/OU=yohlee/CN=NGINX"
# generate ssh key and run
/ \# ssh-keygen -A
/ \# adduser --disabled-password admin
/ \# echo "admin:admin" | chpasswd
/ \# /usr/sbin/sshd
# make directory for running nginx and run server
/ \# mkdir -p /var/run/nginx
/ \# nginx -g "daemon off;"
```
---
### nginx
```Shell
# build ftps image and run
cd /srcs/nginx
docker build -t nginx-image .
kubectl apply -f nginx.yaml
```
- ssh에 접속하기
```Shell
ssh USER@NGINX-EXTERNAL-IP -p PORT
본인의 경우: ssh admin@192.168.99.95 -p 22

- ssh서버 다운시키기
kubectl exec deploy/nginx-deployment -- pkill sshd
이후 ssh admin@192.168.99.95 -p 22 로 접속을 시도해보면 `connection refused`가 나타난다.
이 경우를 방지하기 위해 livenessprobe를 사용함. 잠시 기다렸다가 다시 접속해보자.
* 경고가 나타난다면 vi ~/.ssh/known-hosts 에서 192.168.99.95에서 접속할 때 사용했던 rsa key를 지워주자.
```
---
### ftps

##### reference
https://github.com/lhauspie/docker-vsftpd-alpine

```Shell
# build ftps image and run
cd /srcs/ftps
docker build -t ftps-image .
kubectl apply -f vsftpd.yaml
# file upload
curl ftp://EXTERNAL-IP:21 --ssl -k -u admin:admin -T filename
본인의 경우: curl ftp://192.168.99.96:21 --ssl -k -u admin:admin -T filename
# file download
curl ftp://EXTERNAL-IP:21/filename --ssl -k -u admin:admin -o ./filename
본인의 경우: curl ftp://192.168.99.96:21/filename --ssl -k -u admin:admin -o ./filename
# check
kubectl get pods
kubectl exec -it ftps-pods-name -- sh 
/ \# cd home/vsftpd/user/
# kill vsftpd server
kubectl exec deploy/ftps-deployment -- pkill vsftpd
-> `(6) Could not resolve host: EXTERNAL-IP`
```
---
### mysql
```Shell
# build mysql image and run
cd /srcs/mysql
docker build -t mysql-image .
kubectl apply -f mysql.yaml
# check generated wordpress table
kubectl exec -it mysql-pods-name -- sh 
/ \# cd var/lib/mysql/wordpress
```
---
### phpmyadmin
```Shell
# build phpmyadmin image and run
cd /srcs/phpmyadmin
docker build -t phpmyadmin-image .
kubectl apply -f phpmyadmin.yaml
# check login success
minikube dashboard

move `EXTERNALIP:phpmyadmin-PORT/`
and check `wordpress table`
```
---
### wordpress
```Shell
# build wordpress image and run
cd /srcs/wordpress
```

At first, build dockerfile without `wordpress.sql` file.

** Dockerfile
```Shell
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
COPY entrypoint.sh /tmp/

EXPOSE 5050
ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]
```

** wp-config.php
```php
...
...

define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'USER' );

/** MySQL database password */
define( 'DB_PASSWORD', 'PASSWORD' );

/** MySQL hostname */
define( 'DB_HOST', 'YOUR_MYSQL_SERVICE_NAME' );
define( 'WP_HOME', 'http://YOUR_EXTERNAL_IP:5050/' );
define( 'WP_SITEURL', 'http://YOUR_EXTERNAL_IP:5050/' );

...
...
```

** entrypoint.sh
```Shell
#!/bin/sh

sleep 5
# sh /tmp/init-wordpress.sh # here
php -S 0.0.0.0:5050 -t /etc/wordpress/
until [ $? != 1 ]
do
	php -S 0.0.0.0:5050 -t /etc/wordpress/
done
```

```Shell
docker build -t wordpress-image .
kubectl apply -f wordpress.yaml
```

And then 
1. connect wordpress in your web.
2. install wordpress.
3. create users and post.
4. move phpmyadmin and check your database
5. export your `wordpress.sql`
6. execute the rest files.

My Root User
* user: admin
* pass: lLp)3y6mXqwaZA(s3N
---
### influxdb

- influxdb는 시계열데이터를 저장하는 데이터베이스로, 데이터를 수집하는 telegraf, 대시보드화 시키는 grafana와 주로 함께 사용된다.
- 효율성이 좋기 때문에 influxdb는 60%가 넘는 점유율을 차지하고 있으며, 점점 사용량이 많아지는 추세임. 기본적으로 8086 포트와 연결된다.
- 쿠버네티스를 이용하여 influxdb를 구축하기 위해서는, 알파인 리눅스 환경에서 influxdb를 실행 후 conf파일을 준비해놓을 필요가 있다. `/etc/infuxdb.conf/`
- mysql과 동일하게 persistent volume claim을 이용하여 telegraf와 grafana등 다른 컨테이너에서 접속할 수 있게끔 설정을 해주어야 한다. 미리 준비해놓은 conf파일을 컨피그맵으로 설정하고, yaml파일에서 환경변수들을 이용하여 서버를 초기화한다.

* preparation
```Shell
docker run -it alpine
/ \# apk add influxdb
/ \# vi /etc/influxdb.conf
copy and paste
```

```Shell
# build influxdb image and run
cd /srcs/influxdb
docker build -t influxdb-image .
kubectl apply -f influxdb.yaml
```
---
### telegraf

- telegraf는 데이터 수집을 위한 컨테이너이다. 위의 과정까지 진행했으면, influxdb에 telegraf라는 '빈' 데이터베이스가 만들어져있는데, 이 telegraf 컨테이너를 통해 수집한 데이터를 influxdb에 저장시켜줄 것이다.
- alpine linux환경에서 telegraf를 install한 뒤 conf파일을 이용하여 수집하려는 데이터의 input과 수집한 데이터를 저장할 output을 지정해야 한다.

* preparation
```Shell
docker run -it alpine
/ \# apk add telegraf --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
/ \# vi /etc/telegraf.conf
copy and paste
```

```Shell
# build telegraf image and run
cd /srcs/telegraf
docker build -t telegraf-image .
kubectl apply -f telegraf.yaml
```
---
### grafana
- grafana의 dashboard에서는 수집하고 저장한 시계열 데이터를 시각화하여 볼 수 있다.
- 쿠버네티스로 grafana를 이용하기 위해서는 아래와 같이 /usr/share/grafana/conf 폴더를 미리 준비한 이후 yaml파일을 통해 config 파일들을 수정해야 한다.
* preparation
```Shell
docker run -it -p 30000:3000 alpine /bin/sh
/ \# apk add grafana --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --no-cache
/ \# /usr/sbin/grafana-server --homepath=/usr/share/grafana

if you\'re using kubernetes, check `minikube docker-env` command and move CONTAINER_IP:30000

* id: admin
* pwd: admin

docker cp CONTAINER_ID:/usr/share/grafana/conf .
```
- 도커 컨테이너에서 grafana의 conf폴더를 가져온 이후에, provisioning의 datasource와 dashboards 폴더의 yaml파일을 이용한다.

** grafana dashboard init파일 만들기
쿠버네티스 컨테이너를 모두 실행시킨 뒤 아래의 도커파일과 yaml파일로 grafana 컨테이너에 접속한다.

```Shell
FROM alpine:latest
MAINTAINER yohlee <yohlee@student.42seoul.kr>

RUN apk add grafana --repository=http://dl-3.alpinelinux.org/alpine/edge/testing/

COPY entrypoint.sh /tmp/

EXPOSE 3000

ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]
```
```
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  labels:
    app: grafana
spec:
  selector:
    app: grafana
  type: LoadBalancer
  ports:
    - port: 3000
      name: port
      targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-deployment
  labels:
    app: grafana
spec:
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      name: grafana-pod
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana-container
          image: grafana-image
          imagePullPolicy: Never
          ports:
            - containerPort: 3000
              name: grafana-port
```
이후 EXTERNAL-IP로 그라파나 대시보드에 접속한다. 초기 유저/패스워드는 admin/admin.

CREATE DASHBOARD -> default database 를 influxdb 로 변경 -> 여러 세팅을 거쳐 시각화를 진행 -> json파일로 다운로드

이후 이미지를 빌드할 때 json파일들을 /var/lib/grafana/dashboards 경로로 옮겨주면 만들어낸 대시보드를 불러올 수 있다.