#!/bin/bash
#
#  Создано @jahnito 28.05.2025
#
# Скрипт запускает реплику основной БД
#
# Порядок указания образов строгий, 0 - MySQL/MariaDB, 1 - FreeRADIUS, 2 - Adminer

# Адрес сервера основной БД
MASTER_HOST='192.168.12.200'
# Порт сервера основной БД
MASTER_PORT='3306'
# Пароль пользователя root БД
DBROOTPASS='example'
# Каталог для локального хранения данных СУБД
DBDIR='mariadb_replication'
# Пароль пользователя root БД
DBROOTPASS='example'
# Имя временного каталога для временных файлов
TMPDIR='default'
# Результирующий SQL файл для инициализации БД
RESULT='result.sql'
# Перечень образов задействованых в работе сервиса, порядок контейнеров не нарушать
IMAGES=(mariadb:11.7.2-ubi9 freeradius/freeradius-server:3.2.7 adminer:5.0.6-standalone)
# Режим отладки 0 - отключен, 1 - включен, дает более детальный вывод и в процессе выполнения дает возможность
# зайти в проинициализированную БД через adminer
DEBUG=1

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

if [ -d $TMPDIR ]
then
    echo -e "Временный каталог $TMPDIR существует, завершаю выполнение сценария\n"
    exit 1
else
    echo -e "Создаю временный каталог $TMPDIR\n"
    mkdir $TMPDIR
fi

# Готовим иницилизирующий конфиг для СУБД с репликой
sed "s/MASTER_HOST=.\+$/MASTER_HOST='$MASTER_HOST',/" setup/3.replinit.sql > $TMPDIR/$RESULT

# Создаем сеть для отладки
docker network create deploy > /dev/null

#
# Создаем структуру базы данных и каталог хранения
#

if [ -d $DBDIR ]
then
    echo -e "Каталог уже существует, необходимо удалить его перед инициализацией\n"
    exit 1
else
    echo -e "Создаю каталог для хранения данных\n"
    mkdir $DBDIR
    chmod 777 $DBDIR
fi

docker run --rm --name mariadb-secondary \
        -v `pwd`/$DBDIR:/var/lib/mysql \
        -v `pwd`/configs/secondary-1.cnf:/etc/mysql/conf.d/secondary-1.cnf:z \
        -v `pwd`/$TMPDIR/$RESULT:/docker-entrypoint-initdb.d/$RESULT:z \
        -w /var/lib/mysql \
        -e MARIADB_ROOT_PASSWORD=$DBROOTPASS \
        -e MYSQL_INITDB_SKIP_TZINFO=Y \
        -d --network deploy \
        ${IMAGES[0]}

read

if [ $DEBUG -eq 1 ]; then
    # Для отладки можно запустить adminer
    docker run --rm --name adminer \
            --network deploy \
            -p 8081:8080 -d ${IMAGES[2]} > /dev/null
    echo -e "Войти в БД http://ip_server:8081\n"
    echo -e "Для продолжения нажми Enter\n"
    read
fi

