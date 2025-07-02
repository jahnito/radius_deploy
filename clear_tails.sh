#!/bin/bash

# Переменная обязательна, т.к. её отсутсвие моежет привести к команде rm -rf /
DIRDB="mariadb"
# Переменная обязательна, т.к. её отсутсвие моежет привести к команде rm -rf /
DIRCONF="default"
FILEDICT="configs/dictionary"
REMDB="n"
REMCONF="n"
REMDICT="n"

#
# Удаляем каталог с БД
#

read -p "Удалить каталог с БД? $DIRDB/ [y,N]: " REMDBNEW
if [ -n "$REMDBNEW" ]; then
    key=${REMDBNEW:0:1}
else
    key=$REMDB
fi

if [ "$key" == "y" ]; then
    echo "Удаляю каталог с БД $DIRDB/"
    rm -rf $DBDIR/
else
    echo "Каталог БД не будет удален"
fi

unset key

#
# Удаляем каталог с временными файлами
# 
read -p "Удалить каталог с временными файлами? $DIRCONF/ [y,N]: " REMCONFNEW
if [ -n "$REMCONFNEW" ]; then
    key=${REMCONFNEW:0:1}
else
    key=$REMCONF
fi

if [ "$key" == "y" ]; then
    echo "Удаляю каталог с временными файлами $DIRCONF/"
    rm -rf $DIRCONF/
else
    echo "Каталог с временными файлами не будет удален"
fi

unset key

#
# Удляем файл словаря
#

read -p "Удалить файл словаря? $DIRCONF/ [y,N]: " REMCONFNEW
if [ -n "$REMCONFNEW" ]; then
    key=${REMCONFNEW:0:1}
else
    key=$REMCONF
fi

if [ "$key" == "y" ]; then
    echo "Удаляю файл словаря с вендорами $FILEDICT"
    rm -rf $FILEDICT
else
    echo "Файл словаря не будет удален"
fi

unset key

