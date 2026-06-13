# tainted-spring-platform

tainted-spring-msa 테스트베드의 로컬 인프라/오케스트레이션 레포.
애플리케이션 코드·계약은 보유하지 않는다.

`docker-compose.yml`에는 인프라 5종 + 마이크로서비스 8개가 모두 정의되어 있습니다(프로파일 없음).
따라서 `make up`은 **전체 스택(13개 컨테이너)**을 기동합니다.

## 사용법
```bash
cp .env.example .env
docker compose build              # 서비스 8개 이미지 빌드 (형제 디렉토리 컨텍스트)
make up                           # 전체 스택 기동 (인프라 5 + 서비스 8, --wait)
make smoke                        # 인프라 5종 연결성 검증
make down                         # 정리 (-v 로 볼륨까지)

# 인프라만 기동 (서비스 없이)
docker compose up -d zookeeper kafka mysql postgres redis
# Kafka UI (http://localhost:8090)
docker compose --profile ui up -d kafka-ui
```

## 제공 인프라
MySQL 8.4 / PostgreSQL 16 / Redis 7 / Kafka 7.6.1 / Zookeeper 7.6.1

## 서비스 (compose 배선)
bff-gateway:8080 · auth-user:8081 · diary:8082 · mindgraph:8083 · counseling:8084 · community:8085 · analytics:8086 · notification:8087

외부 진입점은 BFF **http://localhost:8080** 입니다. 자세한 사용법/ API 예시는 `../tainted-spring-msa/README.md` 참고.
