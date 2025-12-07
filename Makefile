# TCP Bridge - Makefile
# Deploy WebSocket-to-TCP bridge on Google Cloud Run

PROJECT_ID := graphql-category-db
SERVICE_NAME := tcp-bridge
REGION := us-central1
SERVICE_ACCOUNT := cloud-run-sa@$(PROJECT_ID).iam.gserviceaccount.com

.PHONY: help setup permissions deploy logs clean

help:
	@echo "TCP Bridge - Cloud Run Deployment"
	@echo ""
	@echo "Usage:"
	@echo "  make setup       - One-time setup (create service account, enable APIs)"
	@echo "  make permissions - Grant required permissions"
	@echo "  make deploy      - Deploy to Cloud Run"
	@echo "  make logs        - Tail service logs"
	@echo "  make url         - Show service URL"
	@echo "  make clean       - Delete the service"
	@echo ""

setup:
	@echo "🔧 Creating service account..."
	-gcloud iam service-accounts create cloud-run-sa \
		--display-name="Cloud Run Service Account" \
		--project=$(PROJECT_ID)
	@echo "🔧 Enabling APIs..."
	gcloud services enable run.googleapis.com --project=$(PROJECT_ID)
	gcloud services enable cloudbuild.googleapis.com --project=$(PROJECT_ID)
	@echo "✅ Setup complete"

permissions:
	@echo "🔐 Granting Cloud Build permissions..."
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member="serviceAccount:$(SERVICE_ACCOUNT)" \
		--role="roles/cloudbuild.builds.builder"
	@echo "🔐 Granting Storage Admin permissions..."
	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member="serviceAccount:$(SERVICE_ACCOUNT)" \
		--role="roles/storage.admin"
	@echo "✅ Permissions granted"

deploy:
	@echo "🚀 Deploying $(SERVICE_NAME) to Cloud Run..."
	gcloud run deploy $(SERVICE_NAME) \
		--service-account $(SERVICE_ACCOUNT) \
		--build-service-account projects/$(PROJECT_ID)/serviceAccounts/$(SERVICE_ACCOUNT) \
		--source . \
		--region $(REGION) \
		--allow-unauthenticated \
		--project=$(PROJECT_ID)
	@echo "✅ Deployed!"
	@make url

logs:
	gcloud run services logs tail $(SERVICE_NAME) \
		--region $(REGION) \
		--project=$(PROJECT_ID)

url:
	@echo ""
	@echo "🌐 Service URL:"
	@gcloud run services describe $(SERVICE_NAME) \
		--region $(REGION) \
		--project=$(PROJECT_ID) \
		--format="value(status.url)"
	@echo ""
	@echo "📡 WebSocket URL:"
	@echo "wss://$$(gcloud run services describe $(SERVICE_NAME) --region $(REGION) --project=$(PROJECT_ID) --format='value(status.url)' | sed 's|https://||')/tcp"
	@echo ""

clean:
	@echo "🗑️  Deleting $(SERVICE_NAME)..."
	gcloud run services delete $(SERVICE_NAME) \
		--region $(REGION) \
		--project=$(PROJECT_ID) \
		--quiet
	@echo "✅ Deleted"

# First time: make setup && make permissions && make deploy
# After that: make deploy
