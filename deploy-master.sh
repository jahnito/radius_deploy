#!/bin/bash
#
#  Создано @jahnito 05.05.2025
#
# Скрипт подготавливает образы и базу данных для Radius сервера
#
# Копируем из базового конфига схему данных, пользователя радиуса
# задаем данные для подключения к базе данных
#
# Задаем словарь вендоров
#
# Порядок указания образов строгий, 0 - MySQL/MariaDB, 1 - FreeRADIUS, 2 - Adminer
#
# Адрес подключения пользователя к серверу БД (для формирования грантов MySQL)
DBHOST='%'
# Пароль пользователя radius для подключения к БД (для формирования грантов MySQL)
DBPASS='radpass'
# Каталог для локального хранения данных СУБД (каталог сохраняется как внешний volume)
DBDIR='mariadb'
# Пароль пользователя root БД
DBROOTPASS='example'
# Имя временного каталога для временных файлов
TMPDIR='default'
# Результирующий SQL файл для инициализации БД
RESULT='result.sql'
# Перечень образов задействованых в работе сервиса
IMAGES=(mariadb:11.7.2-ubi9 freeradius/freeradius-server:3.2.7 adminer:5.0.6-standalone)
# Конфигурационные файлы извлекаемые из базового образа freeradius
FILES=(/etc/raddb/mods-config/sql/main/mysql/schema.sql /etc/raddb/mods-config/sql/main/mysql/setup.sql /etc/raddb/mods-config/sql/main/mysql/process-radacct.sql /etc/raddb/mods-config/sql/main/mysql/queries.conf /etc/raddb/dictionary)
# Создать тестовых пользователей 1-да, 0-нет
TEST_USERS=1
# Режим отладки 0 - отключен, 1 - включен, дает более детальный вывод и в процессе выполнения дает возможность
# зайти в проинициализированную БД через adminer
DEBUG=1

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
    echo -e "Временный каталог $TMPDIR существует\n"
    exit 1
else
    echo -e "Создаю временный каталог $TMPDIR\n"
    mkdir $TMPDIR
fi

docker run --rm --name freeradius -v `pwd`/$TMPDIR:/root -d ${IMAGES[1]} > /dev/null

for i in ${FILES[*]}
do
    docker exec -d -u root freeradius cp $i /root/${i##*/}
done

# Подготовка словаря вендоров

cat $TMPDIR/dictionary > configs/dictionary
cat setup/4.vendor_dicts.txt >> configs/dictionary

docker stop freeradius > /dev/null

# Редактируем setup.sql
sed -i.original '/\(^$\|^#\|^.\+#\)/d' $TMPDIR/setup.sql
sed -i "s/localhost/$DBHOST/" $TMPDIR/setup.sql
sed -i "s/radpass/$DBPASS/" $TMPDIR/setup.sql

# Редактируем schema.sql
sed -i.original '/\(^$\|^#\|^.\+#\)/d' default/schema.sql

# Формируем конечный SQL
# echo -e $CRTDB > $TMPDIR/$RESULT
cat setup/1.createdb.sql >> $TMPDIR/$RESULT
echo -e '\n' >> $TMPDIR/$RESULT
cat $TMPDIR/schema.sql >> $TMPDIR/$RESULT
echo -e '\n' >> $TMPDIR/$RESULT
cat $TMPDIR/setup.sql >> $TMPDIR/$RESULT
# echo $REPLUSER >> $TMPDIR/$RESULT
cat setup/2.createrepl.sql >> $TMPDIR/$RESULT

if [ $TEST_USERS -eq 1 ]
then
    cat setup/5.test_users.sql >> $TMPDIR/$RESULT
fi

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

echo -e "Создаю временные контейнеры, создание таблиц и пользовтелей...\n"

# Создаем сеть для отладки
docker network create deploy > /dev/null

# в каталог монтируем подготовленный sql файл /docker-entrypoint-initdb.d
# он выполняется при первом запуске СУБД 

if [ $DEBUG -eq 1 ]; then
    echo -e "Запуск инициализации БД\n"
fi

docker run --rm --name mariadb \
        -v `pwd`/$DBDIR:/var/lib/mysql \
        -v `pwd`/$TMPDIR/$RESULT:/docker-entrypoint-initdb.d/$RESULT:z \
        -v `pwd`/configs/primary-1.cnf:/etc/mysql/conf.d/primary-1.cnf:z \
        -e MARIADB_ROOT_PASSWORD=$DBROOTPASS \
        -d --network deploy \
        ${IMAGES[0]} > /dev/null

if [ $DEBUG -eq 1 ]; then
    echo -e "БД проинициализирована\n"
fi


if [ $DEBUG -eq 1 ]; then
    # Для отладки можно запустить adminer
    docker run --rm --name adminer \
            --network deploy \
            -p 8080:8080 -d ${IMAGES[2]} > /dev/null
    echo -e "Войти в БД http://ip_server:8080\n"
    echo -e "Для продолжения нажми Enter\n"
    read
fi

# Вывод версии
# docker exec -ti mariadb mariadb -uroot -pexample -e "select version()"

# Отображение основной БД
# docker exec -ti mariadb mariadb -uroot -pexample -e "show databases like 'primary%'"

# Вывод статуса мастер ноды
docker exec -ti mariadb mariadb -uroot -pexample -e "show master status"

# Вывод логов мастер ноды
docker exec -ti mariadb mariadb -uroot -pexample -e "show binary logs\G;"


docker stop mariadb > /dev/null

docker stop adminer > /dev/null

docker network rm deploy > /dev/null
