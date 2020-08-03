echo "metalLB delete"
cd metallb
kubectl delete -f metallb.yaml
cd ..

echo "nginx delete"
cd nginx
kubectl delete -f nginx.yaml
cd ..

echo "ftps delete"
cd ftps
kubectl delete -f ftps.yaml
cd ..

echo "mysql delete"
cd mysql
kubectl delete -f mysql.yaml
cd ..

echo "phpmyadmin delete"
cd phpmyadmin
kubectl delete -f phpmyadmin.yaml
cd ..

echo "wordpress delete"
cd wordpress
kubectl delete -f wordpress.yaml
cd ..

echo "influxdb delete"
cd influxdb
kubectl delete -f influxdb.yaml
kubectl delete -f influxdb_config.yaml
cd ..

echo "telegraf delete"
cd telegraf
kubectl delete -f telegraf.yaml
kubectl delete -f telegraf_config.yaml
cd ..

echo "grafana delete"
cd grafana
kubectl delete -f grafana.yaml
kubectl delete -f grafana_config.yaml
cd ..