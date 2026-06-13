# JaCoCo 커버리지 수집 (out-of-process)

실행 중인 8개 Java 서비스에 **jacocoagent 를 `-javaagent` 로 주입**(tcpserver 모드)하고,
블랙박스 테스트(`../../tainted-spring-blackbox-tests`)를 돌린 뒤 각 서비스의 라인 커버리지를 수집한다.
서비스 소스에 손대지 않는 **out-of-process** 방식이다 — README의 설계 의도("JAVA_TOOL_OPTIONS =
품질 도구가 -javaagent 를 주입할 슬롯")를 그대로 활용한다.

## 구성

- `jacocoagent.jar`, `jacococli.jar` — JaCoCo 0.8.13 (Java 8~23 호환).
- `../docker-compose.jacoco.yml` — 각 서비스에 에이전트 마운트 + `JAVA_TOOL_OPTIONS` + tcpserver 포트(`6308x`) 매핑.
- `collect-coverage.sh` — 8개 서비스 덤프 → 컨테이너 jar의 `BOOT-INF/classes` 추출 → 레포 소스와 묶어 리포트 생성 → 라인 커버리지 평균 출력.
- `reports/` — `<svc>/index.html`(HTML), `<svc>.csv`, `summary.csv`.

## 절차

```bash
# 1) 에이전트를 주입한 채로 전체 스택 기동
cd ~/workspace_claude-code/tainted-spring-platform
docker compose -f docker-compose.yml -f docker-compose.jacoco.yml up -d --wait
#   ※ kafka 가 NodeExists 로 실패하면 zookeeper 안정 후 kafka 만 재생성:
#      docker compose -f docker-compose.yml -f docker-compose.jacoco.yml up -d --force-recreate --wait kafka

# 2) (선택) 기동분 커버리지 제거 — "테스트 기여분"만 보고 싶을 때
cd jacoco
for p in 63080 63081 63082 63083 63084 63085 63086 63087; do \
  java -jar jacococli.jar dump --address localhost --port $p --reset --destfile /dev/null; done

# 3) 블랙박스 테스트 실행
cd ../../tainted-spring-blackbox-tests && ./gradlew clean test

# 4) 커버리지 수집 + 리포트 생성
cd ../tainted-spring-platform/jacoco && ./collect-coverage.sh
```

## tcpserver 포트 매핑

| 서비스 | 호스트 포트 |
|---|---|
| bff-gateway | 63080 |
| auth-user | 63081 |
| diary | 63082 |
| mindgraph | 63083 |
| counseling | 63084 |
| community | 63085 |
| analytics | 63086 |
| notification | 63087 |

## 측정 두 가지 관점

- **누적(기동+테스트)**: 에이전트는 서비스 부팅 시점부터 계측하므로 Spring 빈/설정 로딩까지 포함. 떠 있는 시스템 전체가 블랙박스 트래픽 하에서 실행한 코드.
- **테스트 기여분**: 위 2)에서 리셋한 뒤 측정 → 부팅분을 제외하고 **테스트 케이스가 실제로 구동한** 코드. 50% 목표는 이 기준으로 평가했다.

> 라인 커버리지는 `LINE_COVERED / (LINE_COVERED + LINE_MISSED)` 를 `com.tainted.*` 애플리케이션 클래스에 한해 집계한다(프레임워크 제외).
