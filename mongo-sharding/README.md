# Диаграммы

Схема в DrawIO: [Sharding](https://viewer.diagrams.net/?tags=%7B%7D&lightbox=1&highlight=0000ff&edit=_blank&layers=1&nav=1&title=task1.drawio&page-id=U784_ij-aJZ7tw-NRi7e#Uhttps%3A%2F%2Fdrive.google.com%2Fuc%3Fid%3D1TAPihBj_CPJNd-V3agdpqP5-weSMhgB4%26export%3Ddownload)

Ссылка на файл: https://drive.google.com/file/d/1TAPihBj_CPJNd-V3agdpqP5-weSMhgB4/view?usp=sharing

# pymongo-api

## Как запустить

Запускаем mongodb и приложение

```shell
docker compose up -d
```

Настраиваем шардирование: роутер, сервер конфигурации, шарды
```shell
sh ./scripts/setup_sharding.sh
```


Заполняем mongodb данными

```shell
sh ./scripts/setup_data.sh
```

## Как проверить

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080

### Если вы запускаете проект на предоставленной виртуальной машине

Узнать белый ip виртуальной машины

```shell
curl --silent http://ifconfig.me
```

Откройте в браузере http://<ip виртуальной машины>:8080

## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://<ip виртуальной машины>:8080/docs


### Чтобы проверить сколько записи распределены по шардам

Подключаемся к роутеру

```shell
docker exec -it mongos_router mongosh --port 27020
use somedb
db.helloDoc.getShardDistribution();
```

Или


Подключаемся к первой шарде

```shell
docker exec -it shard1 mongosh --port 27018
 > use somedb;
 > db.helloDoc.countDocuments();
 > exit(); 
```

Подключаемся ко второй шарде

```shell
docker exec -it shard2 mongosh --port 27019
 > use somedb;
 > db.helloDoc.countDocuments();
 > exit(); 
```
