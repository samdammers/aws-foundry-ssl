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

validate:
	@echo "validate all the things..."
	@cfn-lint cloudformation/Foundry_Deployment.json

deploy:
	$(AWSCLI) cloudformation deploy --no-fail-on-empty-changeset \
		--stack-name FoundryVTT-Server \
		--template-file cloudformation/Foundry_Deployment.json \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			TakeSnapshots=True \
			FoundryDownloadLink="$(FOUNDRY_DOWNLOAD_LINK)" \
			UseExistingBucket=False \
			S3BucketName=foundry-vtt-server-dammers \
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
			GoogleAPISecret=$(TOP_DOMAIN_API_SECRET)
