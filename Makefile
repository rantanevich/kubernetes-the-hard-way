include .env
export $(shell sed 's/=.*//' .env)


tf-plan:
	$(call terraform,plan)

tf-apply:
	$(call terraform,apply -auto-approve)

tf-destroy:
	$(call terraform,destroy -auto-approve)

pki-gen:
	./pki/generate.sh

kubeconfig-gen:
	./kubeconfig/generate.sh

upload:
	./scripts/upload-files.sh $$GOOGLE_PROJECT

ssh:
	gcloud compute ssh --project $$GOOGLE_PROJECT $$NAME_PREFIX-$(host)

render:
	./templates/generate.sh


define terraform
	terraform -chdir=./terraform $(1) \
		-var google_project=$$GOOGLE_PROJECT \
		-var google_region=$$GOOGLE_REGION \
		-var name_prefix=$$NAME_PREFIX
endef
