# EKS 매니페스트 스켈레톤

서비스별 Deployment/Service/ConfigMap/Secret 매니페스트는 각 서비스 레포의
구현 계획에서 이 디렉토리에 추가된다. 모든 리소스는 `tainted-spring` 네임스페이스에 배포.
서비스 디스커버리는 k8s Service DNS(예: `http://tainted-spring-diary`)를 사용한다.
