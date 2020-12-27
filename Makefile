SHELL = /bin/bash
.SHELLFLAGS = -euco pipefail

AWSCLI      			:= aws

FOUNDRY_DOWNLOAD_LINK 	?= REQUIRED
EMAIL 					?= REQUIRED
KEYPAIR_NAME 			?= Foundry

DOMAIN 					?= REQUIRED
TOP_DOMAIN_API_KEY		?= REQUIRED
TOP_DOMAIN_API_SECRET	?= REQUIRED
SUB_DOMAIN_API_KEY		?= REQUIRED
SUB_DOMAIN_API_SECRET 	?= REQUIRED

S3_BUCKET				?= REQUIRED

validate:
	@echo "validate all the things..."
	@cfn-lint cloudformation/foundry_server.json
	@cfn-lint cloudformation/management_api.yaml

clean: ##=> Clean all the things
	$(info [+] Cleaning dist packages...)
	@rm management_api.out.yaml
	@rm -rf handler.zip

build: clean
	$(info [+] Build service zip)
	@cd src && zip -X -q -r9 $(abspath ./handler.zip) ./ -x \*__pycache__\* -x \*.git\*

sam-local: build
	sam local invoke \
		--template-file cloudformation/management_api.yaml \
		--event test/test.json

package:
	$(info [+] Transform forwarders SAM template and upload to S3)
	@aws cloudformation package \
		--template-file cloudformation/management_api.yaml \
		--output-template-file management_api.out.yaml \
		--s3-bucket dammers-staging

deploy-api:
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name Foundry-API \
		--template-file management_api.out.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			S3BucketName=$(S3_BUCKET) \
			CertArn=$(shell aws acm list-certificates --query "CertificateSummaryList[?DomainName=='api.foundry.$(DOMAIN)'].CertificateArn" --output text) \
		--tags \
			service=foundry

deploy:
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name FoundryVTT-Server \
		--template-file cloudformation/foundry_server.json \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			TakeSnapshots=True \
			FoundryDownloadLink="$(FOUNDRY_DOWNLOAD_LINK)" \
			UseExistingBucket=False \
			S3BucketName=$(S3_BUCKET) \
			SnapshotFrequency=Weekly \
			OptionalFixedIP=False \
			InstanceKey=$(KEYPAIR_NAME) \
			InstanceType=t3.micro \
			AMI="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2" \
			FullyQualifiedDomainName=$(DOMAIN) \
			SubdomainName=foundry \
			APIKey=$(SUB_DOMAIN_API_KEY) \
			APISecret=$(SUB_DOMAIN_API_SECRET) \
			Email=$(EMAIL) \
			DomainRegistrar=google \
			WebServerBool=True \
			GoogleAPIKey=$(TOP_DOMAIN_API_KEY) \
			GoogleAPISecret=$(TOP_DOMAIN_API_SECRET) \
		--tags \
			service=foundry
