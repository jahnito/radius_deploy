#!/bin/bash
#
#  Создано @jahnito 05.05.2025
#
# Скрипт подготавливает образы и базу данных для Radius сервера
#
# Копируем из базового конфига схему данных, пользователя радиуса
# задаем данные для подключения к базе данных
DBHOST='%'
DBPASS='radpass'
DBDIR='mariadb'
DBROOTPASS='example'
TMPDIR='default'
RESULT='result.sql'
IMAGES=(mariadb:11.7.2-ubi9 freeradius/freeradius-server:3.2.7-alpine adminer:5.0.6-standalone)
FILES=(schema.sql setup.sql process-radacct.sql queries.conf)
CT='CREATE DATABASE IF NOT EXISTS `radius` DEFAULT CHARACTER SET utf8mb4;\nUSE `radius`;\n'

#
# Загрузка образов
#

echo -e 'Загрузка образов...\n'

installed_imgs=`docker image ls --format "{{.Repository}}:{{.Tag}}"`
for i in ${IMAGES[*]}
do
    k=0
    for j in ${installed_imgs[*]}
    do
        if [ $i == $j ]; then
            k=1
            break
        fi
    done
    if [ $k -eq 0 ]; then
        docker pull $i
    else
        echo 'Образ '$i' уже загружен'
    fi
done

#
# Сборка SQL конфигурации Radius
#

echo -e '\n\nСборка схемы БД...\n'

if [ -d $TMPDIR ]
then
    echo "Временный каталог $TMPDIR существует"
    exit 1
else
    echo "Создаю временный каталог $TMPDIR"
    mkdir $TMPDIR
fi

docker run --rm --name freeradius -v `pwd`/$TMPDIR:/root -d freeradius/freeradius-server:3.2.7-alpine

for i in ${FILES[*]}
do
    docker exec -d -u root freeradius cp /opt/etc/raddb/mods-config/sql/main/mysql/$i /root
    docker exec -d -u root freeradius chmod 666 /root/$i
done

docker stop freeradius

# Редактируем setup.sql
sed -i.original '/\(^$\|^#\|^.\+#\)/d' $TMPDIR/setup.sql
sed -i "s/localhost/$DBHOST/" $TMPDIR/setup.sql
sed -i "s/radpass/$DBPASS/" $TMPDIR/setup.sql

# Редактируем schema.sql
sed -i.original '/\(^$\|^#\|^.\+#\)/d' default/schema.sql

# Формируем конечный SQL
echo -e $CT > $TMPDIR/$RESULT
cat $TMPDIR/schema.sql >> $TMPDIR/$RESULT
echo -e '\n' >> $TMPDIR/$RESULT
cat $TMPDIR/setup.sql >> $TMPDIR/$RESULT

#
# Создаем структуру базы данных и каталог хранения
#

if [ -d $DBDIR ]
then
    echo "Каталог уже существует, необходимо удалить его перед инициализацией"
    exit 1
else
    echo "Создаю каталог для хранения данных"
    mkdir $DBDIR
    chmod 777 $DBDIR
fi

echo -e "\n\nСоздание временных контейнеров, создание таблиц и пользовтелей..."

docker network create deploy

# в каталог монтируем подготовленный sql файл /docker-entrypoint-initdb.d
# он выполняется при запуске 

docker run --rm --name mariadb \
        -v `pwd`/$DBDIR:/var/lib/mysql \
        -v `pwd`/$TMPDIR/$RESULT:/docker-entrypoint-initdb.d/$RESULT \
        -d -e MARIADB_ROOT_PASSWORD=$DBROOTPASS \
        --network deploy \
        mariadb:11.7.2-ubi9

docker stop mariadb

docker network rm test

# Для отладки можно запустить adminer
# docker run --rm --name adminer \
#            --network deploy \
#            -p 8080:8080 -d adminer:5.0.6-standalone


