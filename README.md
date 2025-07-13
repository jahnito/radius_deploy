# radius_deploy

Автоматизация запуска кластеризированного RADIUS сервера на базе 

 - FreeRadius
 - MariaDB/MySQL
 - Adminer


1. Запускаем сценарий deploy-master.sh для подготовки конфигов и рабочих каталогов

./deploy-master.sh

2. Запускаем основной сервер

docker compose -f docker-compose-main-node.yml -p main-node up -d


### Добавление пользователей/групп

Создание пользователя

```
INSERT INTO radcheck (username, attribute, op, VALUE) VALUES ('USERNAME', 'Cleartext-Password', ':=', 'PASSWORD');
```

#### Cisco

Добавление группы с привлегией 15 (создается единожды) 

```
INSERT INTO radgroupreply (`groupname`, `attribute`, `op`, `value`) VALUES ('CiscoAvpairL15',	'cisco-avpair',	':=',	'shell:priv-lvl=15');
```

Добавление пользователя в группу Cisco 

```
INSERT INTO radusergroup (`username`, `groupname`, `priority`) VALUES ('USERNAME', 'CiscoAvpairL15', 5);
```

#### Mikrotik

Добавление групп c разными привелегиями (создается один раз) 

```
INSERT INTO radgroupreply (groupname, attribute, op, VALUE) VALUES ("MikrotikFull", "Mikrotik-Group", ":=", "full");
INSERT INTO radgroupreply (groupname, attribute, op, VALUE) VALUES ("MikrotikWrite", "Mikrotik-Group", ":=", "write");
INSERT INTO radgroupreply (groupname, attribute, op, VALUE) VALUES ("MikrotikRead", "Mikrotik-Group", ":=", "read");
```

Добавление пользователя в группу 

```
INSERT INTO radusergroup (username, groupname, priority) VALUES ("USERNAME", "MikrotikFull", 10);
```

### Настройки доступа к оборудованию

#### Доступ в Cisco

```
aaa authentication login default local group radius
aaa authentication enable default enable
aaa authorization exec default local group radius


radius server prm-ad01-app120
 address ipv4 10.168.1.20 auth-port 1812 acct-port 1813
 key 0 FreeR4d1u5!
```

#### Доступ в Mikrotik

Router OS 7+

```
user/aaa/set use-radius=yes

user/aaa/set default-group=full

radius/add service=login address=10.168.1.20 protocol=udp secret=FreeR4d1u5! authentication-port=1812 accounting-port=1813
```


Router OS 6+

```
user aaa set use-radius=yes

user aaa set default-group=full

radius add service=login address=10.168.1.20 protocol=udp secret=FreeR4d1u5! authentication-port=1812 accounting-port=1813
```


### links

https://mariadb.org/mariadb-replication-using-containers/

https://habr.com/ru/articles/532216/

https://techexpert.tips/ru/mikrotik-ru/mikrotik-%D1%80%D0%B0%D0%B4%D0%B8%D1%83%D1%81-%D0%B0%D1%83%D1%82%D0%B5%D0%BD%D1%82%D0%B8%D1%84%D0%B8%D0%BA%D0%B0%D1%86%D0%B8%D0%B8-%D1%81-%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E-freeradius/

