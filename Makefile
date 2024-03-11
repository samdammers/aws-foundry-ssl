SHELL = /bin/bash
.SHELLFLAGS = -euco pipefail

AWSCLI      			:= aws

FOUNDRY_DOWNLOAD_LINK  	?= REQUIRED
FOUNDRY_DOWNLOAD_BUCKET	?= REQUIRED
ADMIN_USER_PASSWORD		?= REQUIRED
DOMAIN					?= REQUIRED
LETS_ENCRYPT_CERT		?= False
EMAIL					?= REQUIRED
KEYPAIR_NAME			?= REQUIRED
SSH_IPV4_ADDRESS		?= ""
S3_BUCKET				?= REQUIRED
GITHUB_REPO				?= REQUIRED

validate:
	@echo "validate all the things..."
	@cfn-lint cloudformation/Foundry_Deployment.json
	@cfn-lint cloudformation/Management_API.yaml

clean: ##=> Clean all the things
	$(info [+] Cleaning dist packages...)
	@rm -f management_api.out.yaml
	@rm -f handler.zip

build: clean
	$(info [+] Build service zip)
	@cd src && zip -X -q -r9 $(abspath ./handler.zip) ./ -x \*__pycache__\* -x \*.git\*

sam-local: build
	sam local invoke \
		--template-file cloudformation/Management_API.yaml \
		--event test/add_ip.json

package: build
	$(info [+] Transform forwarders SAM template and upload to S3)
	@aws cloudformation package \
		--template-file cloudformation/Management_API.yaml \
		--output-template-file Management_API.out.yaml \
		--s3-bucket metalisticpain-foundry-data

cert:
	$(AWSCLI) acm request-certificate --domain-name api.foundry.$(DOMAIN) --validation-method DNS

deploy-api: package
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name Foundry-API \
		--template-file Management_API.out.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			S3BucketName=$(S3_BUCKET) \
			CertArn=$(shell aws acm list-certificates --query "CertificateSummaryList[?DomainName=='api.foundry.$(DOMAIN)'].CertificateArn" --output text) \
			Domain="$(DOMAIN)" \
			HostedZoneId=$(shell aws route53 list-hosted-zones --query "HostedZones[?Name=='$(DOMAIN).'].Id" --output text | cut -d / -f3) \
		--tags \
			service=foundry

deploy-server:
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name FoundryVTT-Server \
		--template-file cloudformation/Foundry_Deployment.json \
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
			UseLetsEncryptTLS=$(LETS_ENCRYPT_CERT) \
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
			GithubRepo=$(GITHUB_REPO) \
		--tags \
			service=foundry \
		--no-execute-changeset
