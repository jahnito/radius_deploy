#!/bin/bash
docker exec -ti mariadb mariadb -uroot -pexample -e "select version()"
