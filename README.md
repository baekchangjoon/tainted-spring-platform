# tainted-spring-platform

tainted-spring-msa 테스트베드의 로컬 인프라/오케스트레이션 레포.
애플리케이션 코드·계약은 보유하지 않는다.

## 사용법
```bash
cp .env.example .env
make up      # 인프라 기동
make smoke   # 인프라 연결성 검증
make down    # 정리
```

## 제공 인프라
MySQL 8.4 / PostgreSQL 16 / Redis 7 / Kafka 7.6.1 / Zookeeper 7.6.1
```
