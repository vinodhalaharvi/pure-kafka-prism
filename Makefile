# Local Kafka - Makefile

.PHONY: help up down logs status topics produce consume clean

help:
	@echo "Local Kafka - Docker Compose"
	@echo ""
	@echo "Usage:"
	@echo "  make up       - Start Kafka + Zookeeper"
	@echo "  make down     - Stop everything"
	@echo "  make logs     - Tail Kafka logs"
	@echo "  make status   - Show container status"
	@echo "  make topics   - List topics"
	@echo "  make create   - Create test topic"
	@echo "  make produce  - Produce test messages"
	@echo "  make consume  - Consume from test topic"
	@echo "  make clean    - Stop and remove volumes"
	@echo ""

up:
	@echo "🚀 Starting Kafka..."
	docker-compose up -d
	@echo ""
	@echo "✅ Kafka running at localhost:9092"
	@echo "✅ Kafka UI at http://localhost:8080"
	@echo ""
	@echo "Waiting for Kafka to be ready..."
	@sleep 5
	@make status

down:
	@echo "🛑 Stopping Kafka..."
	docker-compose down

logs:
	docker-compose logs -f kafka

status:
	@echo ""
	@docker-compose ps
	@echo ""

topics:
	@echo "📋 Listing topics..."
	docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

create:
	@echo "📦 Creating test topic..."
	docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
		--create --topic test-topic --partitions 3 --replication-factor 1 \
		--if-not-exists
	docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
		--create --topic orders --partitions 3 --replication-factor 1 \
		--if-not-exists
	docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
		--create --topic payments --partitions 2 --replication-factor 1 \
		--if-not-exists
	@echo "✅ Topics created"
	@make topics

produce:
	@echo "📤 Producing test messages..."
	@echo '{"event":"purchase","amount":99.99,"user":"user-123"}' | docker exec -i kafka kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic
	@echo '{"event":"view","page":"/home","user":"user-456"}' | docker exec -i kafka kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic
	@echo '{"event":"click","button":"buy","user":"user-123"}' | docker exec -i kafka kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic
	@echo "✅ Messages produced to test-topic"

consume:
	@echo "📥 Consuming from test-topic (Ctrl+C to stop)..."
	docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 \
		--topic test-topic --from-beginning

clean:
	@echo "🗑️  Cleaning up..."
	docker-compose down -v
	@echo "✅ Cleaned"

# Quick test flow:
# make up && make create && make produce
