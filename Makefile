include .env
export $(shell sed 's/=.*//' .env)

TERRAFORM_DIR := ./terraform


tf-plan:
	$(call terraform,plan)

tf-apply:
	$(call terraform,apply -auto-approve)

pki-gen:
	./pki/generate.sh

upload:
	./scripts/upload-files.sh $$GOOGLE_PROJECT


define terraform
	terraform -chdir=./terraform $(1) \
		-var google_project=$$GOOGLE_PROJECT \
		-var google_region=$$GOOGLE_REGION
endef
