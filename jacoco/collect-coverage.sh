#!/usr/bin/env bash
# JaCoCo tcpserver 에서 각 서비스의 커버리지를 덤프하고, 컨테이너 jar의 BOOT-INF/classes 와
# 레포 소스를 묶어 per-service 리포트(HTML+CSV)를 생성한 뒤 라인 커버리지 평균을 출력한다.
#
# 사용: ./collect-coverage.sh
# 사전: 전체 스택이 docker-compose.jacoco.yml 오버라이드로 떠 있어야 함.
set -euo pipefail
cd "$(dirname "$0")"
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 21)}"

CLI=jacococli.jar
WS=../..                       # ~/workspace_claude-code
EXEC=exec
REPORTS=reports
CLASSES=classes
rm -rf "$EXEC" "$REPORTS" "$CLASSES"
mkdir -p "$EXEC" "$REPORTS" "$CLASSES"

# svc | host-port | container | repo-dir
SERVICES=(
  "bff-gateway|63080|tainted-spring-platform-bff-gateway-1|tainted-spring-bff-gateway"
  "auth-user|63081|tainted-spring-platform-auth-user-1|tainted-spring-auth-user"
  "diary|63082|tainted-spring-platform-diary-1|tainted-spring-diary"
  "mindgraph|63083|tainted-spring-platform-mindgraph-1|tainted-spring-mindgraph"
  "counseling|63084|tainted-spring-platform-counseling-1|tainted-spring-counseling"
  "community|63085|tainted-spring-platform-community-1|tainted-spring-community"
  "analytics|63086|tainted-spring-platform-analytics-1|tainted-spring-analytics"
  "notification|63087|tainted-spring-platform-notification-1|tainted-spring-notification"
)

SUMMARY="$REPORTS/summary.csv"
echo "service,line_covered,line_missed,line_pct,branch_pct,method_pct" > "$SUMMARY"

for entry in "${SERVICES[@]}"; do
  IFS='|' read -r svc port container repo <<< "$entry"
  echo "── $svc (port $port) ──────────────────────────"

  # 1) 런타임 커버리지 덤프 (reset=false → 누적 유지)
  java -jar "$CLI" dump --address localhost --port "$port" --destfile "$EXEC/$svc.exec" --retry 3 >/dev/null

  # 2) 실행 중인 컨테이너의 jar 에서 애플리케이션 클래스 추출 (정확히 일치하는 바이트코드)
  mkdir -p "$CLASSES/$svc"
  docker cp "$container:/app/app.jar" "$CLASSES/$svc/app.jar" >/dev/null
  ( cd "$CLASSES/$svc" && unzip -oq app.jar 'BOOT-INF/classes/*' 2>/dev/null || unzip -oq app.jar 2>/dev/null; rm -f app.jar )
  if [ -d "$CLASSES/$svc/BOOT-INF/classes" ]; then
    CLSDIR="$CLASSES/$svc/BOOT-INF/classes"
  else
    CLSDIR="$CLASSES/$svc"   # fat-jar 가 아닌 경우 대비
  fi

  # 3) 리포트 생성 (com.tainted.* 애플리케이션 클래스만)
  java -jar "$CLI" report "$EXEC/$svc.exec" \
    --classfiles "$CLSDIR/com" \
    --sourcefiles "$WS/$repo/src/main/java" \
    --html "$REPORTS/$svc" \
    --csv "$REPORTS/$svc.csv" \
    --name "$svc" >/dev/null

  # 4) CSV 집계 (LINE_MISSED=col8, LINE_COVERED=col9, BRANCH 6/7, METHOD 12/13)
  csv="$REPORTS/$svc.csv"
  lc=$(awk -F, 'NR>1{s+=$9}END{print s+0}' "$csv")
  lm=$(awk -F, 'NR>1{s+=$8}END{print s+0}' "$csv")
  lpct=$(awk -v c="$lc" -v m="$lm" 'BEGIN{t=c+m; printf "%.1f", t? 100*c/t:0}')
  bpct=$(awk -F, 'NR>1{c+=$7;m+=$6}END{t=c+m; printf "%.1f", t? 100*c/t:0}' "$csv")
  mpct=$(awk -F, 'NR>1{c+=$13;m+=$12}END{t=c+m; printf "%.1f", t? 100*c/t:0}' "$csv")
  ltot=$(awk -v c="$lc" -v m="$lm" 'BEGIN{print c+m}')
  printf "   line %s%%  %s/%s lines  branch %s%%  method %s%%\n" "$lpct" "$lc" "$ltot" "$bpct" "$mpct"
  echo "$svc,$lc,$lm,$lpct,$bpct,$mpct" >> "$SUMMARY"
done

echo "════════════════════════════════════════════════"
awk -F, 'NR>1{sum+=$4; n++} END{printf "서비스 %d개 · 라인 커버리지 단순평균: %.1f%%\n", n, n? sum/n:0}' "$SUMMARY"
echo "요약: $REPORTS/summary.csv   |  HTML: $REPORTS/<svc>/index.html"
