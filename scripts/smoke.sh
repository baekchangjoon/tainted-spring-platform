#!/usr/bin/env bash
# 5종 인프라가 실제로 응답하는지 docker compose exec 로 검증한다.
set -euo pipefail

fail() { echo "SMOKE FAIL: $1"; exit 1; }

echo "[1/5] zookeeper..."
# cub(Confluent Utility Belt)는 cp-* 이미지에 기본 포함 — nc 등 외부 바이너리에 의존하지 않음.
docker compose exec -T zookeeper cub zk-ready localhost:2181 10 || fail "zookeeper"

echo "[2/5] kafka..."
docker compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list >/dev/null || fail "kafka"

echo "[3/5] mysql..."
docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 --silent || fail "mysql"
docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"' | grep -q authuser || fail "mysql db authuser"
docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"' | grep -q community || fail "mysql db community"

echo "[4/5] postgres..."
docker compose exec -T postgres pg_isready -U postgres >/dev/null || fail "postgres"
for db in diary mindgraph analytics; do
  docker compose exec -T postgres psql -U postgres -lqt | cut -d'|' -f1 | grep -qw "$db" || fail "postgres db $db"
done

echo "[5/5] redis..."
docker compose exec -T redis redis-cli ping | grep -q PONG || fail "redis"

echo "SMOKE OK: all infrastructure healthy"
