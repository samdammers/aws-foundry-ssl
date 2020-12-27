# AWS Foundry VTT Deployment with SSL Encryption

_Deploys Foundry VTT with SSL encryption in AWS using CloudFormation (Beginner Friendly)_

This is an upgraded version of the [original](https://www.reddit.com/r/FoundryVTT/comments/iurf7h/i_created_a_method_to_automatically_deploy_a/) beginner friendly automated AWS deployment Lupert and I worked on. We did some tinkering and it now handles setup and creation of AWS resources, in addition to fully configuring reverse proxy and certificate renewal. **tldr**: You can now use audio and video in Foundry to your heart's content!

Head to the [**wiki page**](https://github.com/cat-box/aws-foundry-ssl/wiki) for the full instructions, and remember: **READ EVERY. SINGLE. PAGE**.

# Additions

Added an api to enable me to whitelist player IP's for the s3 static assets.
This was done so I didn't leave public assets I bought from DnD Map creators

Also added a stop/start server api so I can save costs by shutting it down between sessions

* /ip/add (adds the users x-forwarded-for IP address to s3 bucket policy)
* /ip/rest (to reset and remove access, also is executed once a day by aws event schedule)
* /start (starts foundry ec2 server)
* /stop (stops foundry ec2 server)

# Deployment

## Requirements

* AWS CLI
* Python > 3.7
  * Boto3
  * [AWS SAM](https://aws.amazon.com/serverless/sam/)
  * CFNLint
* Docker (if running sam local)
* GNUMake

### API Certificates

API Certificate was provisioned manually prior to deployment.

`aws acm request-certificate --domain-name api.foundry.$(DOMAIN) --validation-method EMAIL --domain-validation-options DomainName=api.foundry.$(DOMAIN),ValidationDomain=$(DOMAIN)`

As I used google DNS, I needed to ensure the validation domain was my primary so I received the webmaster emails

Once the API GW was provisioned, a CNAME was required

Name | Type | TTL | Data
|---|---|---|---|
| `api.foundry` | CNAME  | 1 Hour  | `${GUID}.execute-api.${REGION}.amazonaws.com.`  |

The Data value is the `API Gateway domain name` on the Custom Domain Name screen in AWS. 
Not to be confused with the execute-api GUID on the actual API GW.

## Build

`gmake build`

## Test

I haven't put in any unit tests 😱
Can use the json test file under `test/` and run sam local for functional integrated testing

`gmake sam-local`

## Deployment

`gmake package deploy deploy-api`