# AWS Foundry VTT CloudFormation Deployment with TLS Encryption

This is a fork of the [**Foundry CF deploy script**](https://github.com/cat-box/aws-foundry-ssl) by Lupert and Cat.

**New Things**

- Supports Foundry 11/12+
- Amazon Linux 2023 on Graviton EC2s
- Node 20.x
- [IPv6 support](docs/IPv6.md)

Note this is just something being done in my spare time and for fun/interest. If you have any contributions, they're welcome. Please note that I'm only focusing on AWS as the supported hosting service.

## Installation

You'll need some technical expertise and basic familiarity with AWS to get this running. It's not quite click-ops, but it's close. Some parts do require some click-ops once.

You can also refer to the original repo's wiki, but the gist is:

### Requirements

* AWS CLI
* direnv+
* Python > 3.12
  * Boto3
  * [AWS SAM](https://aws.amazon.com/serverless/sam/)
  * CFNLint
* Docker (if running sam local)
* GNUMake

### Foundry VTT Download

Download the `NodeJS` installer for Foundry VTT from the [Foundry VTT website](https://foundryvtt.com/). Then either:

- Upload it to a manually created S3 bucket (see AWS Pre-setup below)
- Upload it to Google Drive, make the link publicly shared (anyone with the link can view) (I had issues with this working)
- Have a Foundry VTT Patreon download link handy, or
- Generate a time-limited link from the Foundry VTT site; This option isn't really recommended, but if that works for you then that's cool

Once your server is up and running, if you used eg. a Google Drive link or your own hosted site, you can remove the installer as it's not used past the initial deployment.

### AWS Pre-setup

This only needs to be done _once_, no matter how many times you redeploy.

- Create an SSH key in **EC2**, under `EC2 / Key Pairs`
  - Keep the downloaded private keypair (PEM or PPK) file safe, you'll need it for [SSH / SCP access](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html) to the EC2 server instance
  - If you tear down and redeploy the CloudFormation stack you can reuse the same SSH key

- Create an IAM User with access key (terrible I know) for CLI access
  - Consider rotating these keys regularly as a good security practise

- Create a staging bucket for your foundry artifact

### AWS Setup

**Note:** This script currently only supports your _default VPC_, which should have been created automatically when you first signed up for your AWS acccount.

If you want to use IPv6, see [the IPv6 docs](docs/IPv6.md) for how to configure your default VPC.

#### CLI
- Copy .envrc.example to .envrc
  - amend as required with your variables, credentials, staging bucket etc
- execute `make deploy-server` to deploy the foundry server
  - It should be pretty automated from there. Again, just be careful of the LetsEncrypt TLS issuance limits.
  - If need be, set the LetsEncrypt TLS testing option to `False` in the CloudFormation setup if you are debugging a failed stack deploy. Should you run out of LetsEncrypt TLS requests, you'll need to wait one week before trying again.

- execute `make cert` - This creates a certificate for your API, only required _the first time_
- execute `make deploy-api` - This creates the Python lambda and API at api.foundry.${domain}

#### Console
- Go to **CloudFormation** and choose to **Create a Stack** with new resources
  - Leave `Template is Ready` selected
  - Choose `Upload a template file`
  - Upload the `/cloudformation/Foundry_Deployment.yaml` file from this project
  - Fill in and check _all_ the details. I've tried to provide sensible defaults. At a minimum if you leave the defaults, the ones that need to be filled in are:
    - The link for downloading Foundry
    - An admin user password (for IAM)
    - Your domain name and TLD eg. `mydomain.com`
      - **Important:** Do _not_ include `www` or any other sub-domain prefix
    - Your email address for LetsEncrypt TLS (https) certificate issuance
    - The SSH keypair you previously set up in `EC2 / Key Pairs`
    - Choose whether the S3 bucket already exists, or if it should be created
    - The S3 bucket name for storing files
      - This name must be _globally unique_ across all S3 buckets that exist on AWS
      - If you host Foundry on eg. `foundry.mydomain.com` then `foundry-mydomain-com` is a good recommendation
It should be pretty automated from there.
It should be automated from there. If all goes well, the server will take around five minutes or so to become accessible.

### AWS Setup CLI

**Note:** This repo currently relies on your `default` VPC, which should be set up automatically when you first create your acccount. If you have a custom VPC, it's not (yet) supported.

- Copy .envrc.example to .envrc
  - amend as required with your variables, credentials, staging bucket etc
- execute `make deploy-server` to deploy the foundry server
  - It should be pretty automated from there. Again, just be careful of the LetsEncrypt TLS issuance limits.
  - If need be, set the LetsEncrypt TLS testing option to `False` in the CloudFormation setup if you are debugging a failed stack deploy. Should you run out of LetsEncrypt TLS requests, you'll need to wait one week before trying again.

- execute `make cert` - This creates a certificate for your API, only required _the first time_
- execute `make deploy-api` - This creates the Python lambda and API at api.foundry.${domain}

### API

The api can control a few things
- GET /ip/add - Add your current IP address (as determined by X-Forwarded-For) to the S3 bucket policy
- GET /ip/reset - Purge all current IP's barring the defaults
- GET /start - start the EC2 Foundry server
- GET /stop - stop the EC2 Foundry Server


### Optional SSH Access

If you want to allow yourself access via SSH, you must specify a valid [subnet range](https://www.calculator.net/ip-subnet-calculator.html) for your [IPv4 / IPv6 address](https://www.whatismyip.com/).

- For IPv4 access, use `[your IPv4 address]/32` unless you know what you're doing
- For IPv6 access, use `[your IPv6 address]/128` unless you know what you're doing
  - As IPv6 device addresses change quite frequently, it's likely this will need to be updated often until you know what a more permissive subnet range looks like for you; A more permissive IPv6 range might be `0123:4567:89ab::/64` for example

You can always manually add or update SSH access later in `EC2 / Security Groups` in the AWS Console.

## Running the Server on a Schedule

If you don't have a need for your Foundry server to run 24/7, **AWS Systems Manager** lets you configure a simple schedule to start and stop your EC2 Foundry instance and save on hosting costs.

1. From the AWS Console, navigate to `Systems Manager`
1. Then,
   - if this is your first time using System Manager, choose `Quick Setup`, or
   - if you already have other services configured in Systems Manager, choose `Quick Setup` and then click the `Create` button

1. Choose `Resource Scheduler`

   - Enter a tag name of `Name` with a value of `[the Foundry CloudFormation stack name]-Server`
     - You can find the server name in `EC2 / Instances` if you're unsure
   - Choose which days and what times on those days you want the server to be active
   - Choose `Current Account` and `Current Region` as targets unless your needs differ

1. Create the schedule

Once it's successfully provisioned, the next time it ticks over a trigger time the Foundry EC2 server will be started or stopped as appropriate, saving you from paying for time that you aren't using the server.

If you _do_ need to access the server outside of the schedule, you can always start and stop it manually from the EC2 list without affecting the Resource Scheduler.

If your needs are more complex, you could instead consider setting up the [AWS Instance Scheduler stack](https://aws.amazon.com/solutions/implementations/instance-scheduler-on-aws/). There's a nominal cost per month to run the services required.
- Register a domain and have the route53 hostedzone created in the AWS Console

- Create an SSH key in **EC2**, under `EC2 / Network & Security / Key Pairs`
  - You only need to do this once, _the first time_. If you tear down and redeploy the stack you can reuse the same SSH key
  - That said, consider rotating keys regularly as a good security practise
  - Keep the downloaded private keypair (PEM or PPK) file safe, you'll need it for [SSH / SCP access](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html) to the EC2 server instance
  
- Create an IAM User with access key (terrible I know) for CLI access
  - consider rotating keys regularly as a good security practise

- Create a staging bucket for your foundry artifact

## Security and Updates

Linux auto-patching is enabled by default. A utility script `utils/kernel_updates.sh` also exists to help you manage this if you want to disable, re-enable, or run it manually.

It's also recommended to SSH into the instance and run `sudo dnf upgrade` every so often to make sure your packages are up to date with the latest fixes and security releases.

## Upgrading From a Previous Installation

see [Upgrading](docs/UPGRADING.md)

## Debugging Failed CloudFormation

As long as you can get as far as the EC2 being spun up, then:

- If you encounter a creation error, try setting CloudFormation to _preserve_ resources instead of _rollback_ so you can check the troublesome resources
- Disable LetsEncrypt certificate requests (`UseLetsEncryptTLS` set to `False`), until you're happy that it's working to avoid running into the certificate issuance limit
- Add your IP to the Inbound rules of the created Security Group (if you didn't already during the CloudFormation config)
- Grab the EC2's IP from the EC2 web console details
- Open up PuTTy or similar, connect to the IP using the SSH keypair (I'd recommend to only accept the key _once_, rather than accept _always_, as you may end up destroying this instance)
- Check the setup logs
  - `sudo tail -f /tmp/foundry-setup.log` if setup scripts are still running, or
  - `sudo cat /tmp/foundry-setup.log | less` if setup scripts have finished running

Hopefully that gives you some insight in what's going on...

### LetsEncrypt TLS Issuance Limits

Should you run into the allowed LetsEncrypt TLS requests of _5 requests per Fully Qualified Domain Name, per week_, you'll need to wait _one week_ before trying again. You can still access your instance over _non-secure_ `http`.

After a week, you can re-run the issuance request manually, or if you haven't done anything major, you may just tear down the CloudFormation stack and start over.
- Improve CloudWatch logs (?)
- Add script to facilitate transfer between two EC2s?
- Store LetsEncrypt PEM keys in AWS Secrets Manager and retrieve them instead of requesting new ones to work around the issuance limit (is that even possible / supported?)
- Better ownership/permissions defaults?
- Automatically select the `x86_64` or `arm64` image based on instance choice (even possible?)
- Consider using SSH forwarding via SSM or EC2 Instance Connect instead of key pair stuff, would need to look into this
- IPv6 support (AWS will soon start charging for IPv4 address assignments), in progress
- Consider better packaging to remove public github repo cloning but instead use a packaged copy of the repo

## Notes

- The s3 bucket policy contains 3 private range subnets (usually the default vpc subnets)
  - This is intentional despite the lack of use
  - Having more than 1 item ensures the lambda code assumption (that its a list) can be true
    - By all means PR a better code if you would like
  - Having them there does not harm anything

- This install clones the public repository to access scripts
  - Ensure you update the repo to your own if making changes

