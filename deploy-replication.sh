#!/bin/bash
#
#  Создано @jahnito 28.05.2025
#
# Скрипт запускает реплику основной БД
#
# Порядок указания образов строгий, 0 - MySQL/MariaDB, 1 - FreeRADIUS, 2 - Adminer

# Адрес сервера основной БД
MASTER_HOST='10.169.228.245'
# Порт сервера основной БД
MASTER_PORT='3306'
# Пользователь реплицируемой СУБД
MASTER_USER='repluser',
# Пароль пользователя реплицируемой СУБД
MASTER_PASSWORD='replsecret',
# Каталог для локального хранения данных СУБД
DBDIR='mariadb_replication'
# Пароль пользователя root БД
DBROOTPASS='example'
# Имя временного каталога для временных файлов
TMPDIR='default'
# Результирующий SQL файл для инициализации БД
RESULT='result.sql'
# Перечень образов задействованых в работе сервиса
IMAGES=(mariadb:11.7.2-ubi9 freeradius/freeradius-server:3.2.7-alpine adminer:5.0.6-standalone)
# Режим отладки 0 - отключен, 1 - включен, дает более детальный вывод и в процессе выполнения дает возможность
# зайти в проинициализированную БД через adminer
DEBUG=1

