#!/bin/bash

# Настройки
CONFIG_SERVER="configSrv"
SHARD1="shard1"
SHARD2="shard2"
ROUTER="mongos_router"

# Ждём, пока контейнеры полностью запустятся


# Инициализация репликации
init_replica() {
  local container=$1
  local port=$2
  local repl_set=$3
  echo "Инициализация реплицируемого набора ${repl_set} в контейнере ${container}..."
  docker exec -it ${container} mongosh --port ${port} --eval "
    rs.initiate({
      _id: '${repl_set}',
      members: [
        { _id: 0, host: '${container}:${port}' }
      ]
    });
  "
  echo "Репликация ${repl_set} инициализирована."
}

# Добавление шарда в маршрутизатор
add_shard() {
  local shard_name=$1
  local shard_host=$2
  echo "Добавление шарда ${shard_name} (${shard_host}) в маршрутизатор..."
  docker exec -it ${ROUTER} mongosh --port 27020 --eval "
    sh.addShard('${shard_name}/${shard_host}');
  "
  echo "Шард ${shard_name} добавлен."
}

# Основной процесс
echo "=== Запуск настройки шардирования ==="

# 1. Настройка конфигурационного сервера
echo "Инициализация конфигурационного сервера..."
docker exec -it ${CONFIG_SERVER} mongosh --port 27017 --eval "
  rs.initiate({
    _id: 'config_server',
    configsvr: true,
    members: [
      { _id: 0, host: '${CONFIG_SERVER}:27017' }
    ]
  });
"
echo "Конфигурационный сервер инициализирован."

sleep 1

# 2. Настройка репликации для шардов
  init_replica ${SHARD1} 27018 "shard1"
  init_replica ${SHARD2} 27019 "shard2"
sleep 2
# 3. Настройка маршрутизатора
add_shard "shard1" "${SHARD1}:27018"
add_shard "shard2" "${SHARD2}:27019"
sleep 1
# 4. Включение шардирования для базы данных
echo "Включение шардирования для базы данных..."
docker exec -it ${ROUTER} mongosh --port 27020 --eval "
  sh.enableSharding('somedb');
  sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' } );  
"

echo "Шардирование для базы данных настроено."

echo "=== Настройка шардирования завершена ==="
