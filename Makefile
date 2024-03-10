SHELL = /bin/bash
.SHELLFLAGS = -euco pipefail

AWSCLI      			:= aws

FOUNDRY_DOWNLOAD_LINK 	?= REQUIRED
FOUNDRY_DOWNLOAD_BUCKET ?= REQUIRED
ADMIN_USER_PASSWORD		?= REQUIRED
DOMAIN 					?= REQUIRED
EMAIL 					?= REQUIRED
KEYPAIR_NAME 			?= foundry-vtt-melb
SSH_IPV4_ADDRESS		?= ""
S3_BUCKET				?= REQUIRED

validate:
	@echo "validate all the things..."
	@cfn-lint cloudformation/Foundry_Deployment.template
	@cfn-lint cloudformation/Management_API.template

clean: ##=> Clean all the things
	$(info [+] Cleaning dist packages...)
	@rm -f management_api.out.yaml
	@rm -f handler.zip

build: clean
	$(info [+] Build service zip)
	@cd src && zip -X -q -r9 $(abspath ./handler.zip) ./ -x \*__pycache__\* -x \*.git\*

sam-local: build
	sam local invoke \
		--template-file cloudformation/Management_API.template \
		--event test/add_ip.json

package:
	$(info [+] Transform forwarders SAM template and upload to S3)
	@aws cloudformation package \
		--template-file cloudformation/Management_API.template \
		--output-template-file Management_API.out.template \
		--s3-bucket metalisticpain-foundry-data

cert:
	$(AWSCLI) acm request-certificate --domain-name api.foundry.$(DOMAIN) --validation-method DNS

deploy-api:
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name Foundry-API \
		--template-file Management_API.out.template \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			S3BucketName=$(S3_BUCKET) \
			CertArn=$(shell aws acm list-certificates --query "CertificateSummaryList[?DomainName=='api.foundry.$(DOMAIN)'].CertificateArn" --output text) \
			Domain="$(DOMAIN)"
		--tags \
			service=foundry

deploy:
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name FoundryVTT-Server \
		--template-file cloudformation/Foundry_Deployment.template \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			FoundryDownloadLink="$(FOUNDRY_DOWNLOAD_LINK)" \
			FoundryDownloadBucket="$(FOUNDRY_DOWNLOAD_BUCKET)" \
			AdminUserName="FoundryAdmin" \
			AdminUserPW="$(ADMIN_USER_PASSWORD)" \
			FullyQualifiedDomainName="$(DOMAIN)" \
			SubdomainName="foundry" \
			WebServerBool=False \
			ConfigureRoute53Bool=True \
			UseLetsEncryptTLS=True \
			Email=$(EMAIL) \
			InstanceKey=$(KEYPAIR_NAME) \
			InstanceType=t4g.small \
			AMI="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64" \
			UseFixedIP=False \
			SshAccessIPv4="$(SSH_IPV4_ADDRESS)" \
			SshAccessIPv6="" \
			UseExistingBucket=False \
			S3BucketName=$(S3_BUCKET) \
			TakeSnapshots=True \
			SnapshotFrequency=Weekly \
		--tags \
			service=foundry \
		--disable-rollback
