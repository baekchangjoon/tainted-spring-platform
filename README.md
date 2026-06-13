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

## JaCoCo out-of-process 커버리지 수집

실행 중인 8개 Java 서비스에 **jacocoagent 를 `-javaagent`(tcpserver 모드)로 주입**해, 서비스 소스를 수정하지 않고 블랙박스 테스트(`../tainted-spring-blackbox-tests`)가 구동하는 **라인 커버리지**를 수집합니다. `../tainted-spring-msa/README.md`의 설계 의도("JAVA_TOOL_OPTIONS = 품질 도구가 -javaagent 를 주입할 슬롯")를 그대로 활용합니다.

### 구성
- **`docker-compose.jacoco.yml`** — 각 서비스에 에이전트 마운트 + `JAVA_TOOL_OPTIONS` + tcpserver 포트(63080~63087) 매핑 오버라이드
- **`jacoco/collect-coverage.sh`** — 런타임 덤프 → 컨테이너 jar의 `BOOT-INF/classes` 추출 → 레포 소스와 묶어 per-service HTML/CSV 리포트 + 라인 커버리지 평균 출력
- **`jacoco/README.md`** — 절차/포트맵/측정 관점(누적 vs 테스트 기여분) 문서화

### 사용
```bash
docker compose -f docker-compose.yml -f docker-compose.jacoco.yml up -d --wait
cd jacoco && ./collect-coverage.sh   # 테스트는 ../../tainted-spring-blackbox-tests 에서 ./gradlew test
```

### 측정 결과 (블랙박스 스위트 기준)
| 관점 | 평균 라인 커버리지 |
|---|---|
| 누적(부팅+테스트) | ~77.5% |
| 테스트 기여분(부팅분 리셋 후) | **55.2%** |

> 테스트 기여분 기준 평균이 목표 50%를 상회합니다. 개별 서비스: community 77.4 · diary 66.8 · mindgraph 63.1 · analytics 53.8 · bff 49.6 · counseling 47.4 · auth 44.1 · notification 39.8.
