# radius_deploy

Автоматизация запуска кластеризированного RADIUS сервера на базе 

 - FreeRadius
 - MariaDB/MySQL
 - Adminer


1. Запускаем сценарий deploy-master.sh для подготовки конфигов и рабочих каталогов

./deploy-master.sh

2. Запускаем основной сервер

docker compose -f docker-compose-main-node.yml -p main-node up -d






### links

https://mariadb.org/mariadb-replication-using-containers/

https://habr.com/ru/articles/532216/

https://techexpert.tips/ru/mikrotik-ru/mikrotik-%D1%80%D0%B0%D0%B4%D0%B8%D1%83%D1%81-%D0%B0%D1%83%D1%82%D0%B5%D0%BD%D1%82%D0%B8%D1%84%D0%B8%D0%BA%D0%B0%D1%86%D0%B8%D0%B8-%D1%81-%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E-freeradius/

