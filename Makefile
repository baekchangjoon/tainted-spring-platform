.PHONY: up down smoke logs
up:
	docker compose up -d --wait
down:
	docker compose down -v
smoke:
	./scripts/smoke.sh
logs:
	docker compose logs -f
