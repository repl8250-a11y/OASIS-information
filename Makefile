.PHONY: help dev test lint format migrate deploy-local

help:
	@echo "ResearchOS Development Commands"
	@echo "================================"
	@echo "make dev              - Start all services locally"
	@echo "make test             - Run all tests"
	@echo "make lint             - Lint all code"
	@echo "make format           - Format code"
	@echo "make migrate          - Run database migrations"
	@echo "make seed             - Seed development data"
	@echo "make deploy-local     - Deploy to local Kubernetes"
	@echo "make clean            - Clean up containers & volumes"

dev:
	docker-compose -f infrastructure/docker-compose.yml up -d
	sleep 5
	$(MAKE) migrate
	@echo "✓ All services running. Frontend: http://localhost:3000"

test:
	@echo "Running tests across all services..."
	cd services/auth-service && go test ./...
	cd services/discovery-service && go test ./...
	cd services/paper-service && npm test
	cd services/knowledge-graph-service && pytest
	cd frontend && npm test

lint:
	@echo "Linting all services..."
	cd services/auth-service && golangci-lint run
	cd services/discovery-service && golangci-lint run
	cd services/paper-service && npm run lint
	cd services/knowledge-graph-service && pylint src/

format:
	@echo "Formatting code..."
	cd services/auth-service && go fmt ./...
	cd services/discovery-service && go fmt ./...
	cd services/paper-service && npm run format
	cd services/knowledge-graph-service && black src/

migrate:
	@echo "Running database migrations..."
	cd packages/db && psql -f migrations/001_initial_schema.sql

seed:
	@echo "Seeding development data..."
	cd packages/db && psql -f seed/sample_papers.sql

deploy-local:
	kubectl apply -f infrastructure/kubernetes/base/

clean:
	docker-compose -f infrastructure/docker-compose.yml down -v
	@echo "✓ Cleaned up containers and volumes"
