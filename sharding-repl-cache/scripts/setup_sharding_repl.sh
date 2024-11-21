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
  local container_secondary_1=$4
  local port_secondary_1=$5
  local container_secondary_2=$6
  local port_secondary_2=$7
  echo "Инициализация реплицируемого набора ${repl_set} в контейнере ${container}..."
  docker exec -it ${container} mongosh --port ${port} --eval "
    rs.initiate({
      _id: '${repl_set}',
      members: [
        { _id: 0, host: '${container}:${port}' },
        { _id: 1, host: '${container_secondary_1}:${port_secondary_1}' },
        { _id: 2, host: '${container_secondary_2}:${port_secondary_2}' }
      ]
    });
  "
  echo "Репликация ${repl_set} инициализирована."
}

# Добавление шарда в маршрутизатор
add_shard() {
  local shard_name=$1
  local shard_host=$2
  local shard_secondary_1_host=$3
  local shard_secondary_2_host=$4
  echo "Добавление шарда ${shard_name} (${shard_host}) в маршрутизатор..."
  docker exec -it ${ROUTER} mongosh --port 27024 --eval "
    sh.addShard('${shard_name}/${shard_host},${shard_secondary_1_host},${shard_secondary_2_host}');
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
  init_replica ${SHARD1} 27018 "shard1" "shard1_secondary1" 27019  "shard1_secondary2" 27020
  init_replica ${SHARD2} 27021 "shard2"  "shard2_secondary1" 27022  "shard2_secondary2" 27023
sleep 2

# 3. Настройка маршрутизатора
add_shard "shard1" "${SHARD1}:27018" "shard1_secondary1:27019" "shard1_secondary2:27020"
add_shard "shard2" "${SHARD2}:27021" "shard2_secondary1:27022" "shard2_secondary2:27023"
sleep 1

# 4. Включение шардирования для базы данных
echo "Включение шардирования для базы данных..."
docker exec -it ${ROUTER} mongosh --port 27024 --eval "
  sh.enableSharding('somedb');
  sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' } );  
"

echo "Шардирование для базы данных настроено."

echo "=== Настройка шардирования завершена ==="
