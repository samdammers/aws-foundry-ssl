# AWS Foundry VTT CloudFormation Deployment with TLS Encryption

This is a fork of the [**Foundry CF deploy script**](https://github.com/cat-box/aws-foundry-ssl) by Lupert and Cat.

**New Things**

- Supports Foundry 11
- Amazon Linux 2023 on EC2
- Node 20.x
- Newer more cost efficient / performant instance type support, including ARM64
- Experimental IPv6 support

Note this is just something being done in my spare time and for fun/interest. Please keep that in mind.

## Installation

You'll need some technical expertise and basic familiarity with AWS to get this running. It's not quite click-ops, but it's close. Some parts do require some click-ops once.

You can also refer to the original repo's wiki, but the gist is:

### Foundry VTT Download

Download the `NodeJS` installer for Foundry VTT from the Foundry VTT website. Then either:

- Upload it to Google Drive, make the link publicly shared (anyone with the link can view), or
- Have a Foundry VTT Patreon download link handy, or
- Upload it somewhere else it can be fetched publicly

It's _not recommended_ to use the time-limited links that you can get from the Foundry VTT site, but if that works for you, it's also an option.

**Note:** Foundry `11.313` at a minimum is recommended due to Electron fixing a _second_ major security flaw in the WebP decoder.

### AWS Pre-setup

This only needs to be done _once_, no matter how many times you redeploy.

- Create an SSH key in **EC2**, under `EC2 / Network & Security / Key Pairs`
  - You only need to do this once, _the first time_. If you tear down and redeploy the stack you can reuse the same SSH key
  - That said, consider rotating keys regularly as a good security practise
  - Keep the downloaded private keypair (PEM or PPK) file safe, you'll need it for [SSH / SCP access](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html) to the EC2 server instance

### AWS Setup

**Note:** This script currently relies on your `default` VPC, which should be set up automatically when you first create your acccount. If you have a custom VPC, it's not (yet) supported.

- Go to **CloudFormation** and choose to **Create a Stack** with new resources
  - Leave `Template is Ready` selected
  - Choose `Upload a template file`
  - Upload the `/cloudformation/Foundry_Deployment.template` file from this project
  - Fill in and check _all_ the details. I've tried to provide sensible defaults. At a minimum if you leave the defaults, the ones that need to be filled in are:
    - Add the link for downloading Foundry
    - Set an admin user password (for IAM)
    - Enter your domain name and TLD eg. `mydomain.com`
      - **Important:** Do _not_ include `www` or any other sub-domain prefix
    - Enter your email address for LetsEncrypt TLS (https) certificate issuance
    - Choose the SSH key pair you set up in the EC2 Key Pairs
    - _Optional:_ Allow your IP access via SSH eg. `123.45.67.89/32`. The `/xxx` [subnet range](https://www.calculator.net/ip-subnet-calculator.html) on the end is required. For IPv4 access, use `[your IPv4 address]/32` unless you know what you're doing. For IPv6 access, use `[your IPv6 address]/128` unless you know what you're doing. You can always manually set or change this later in **EC2 Security Groups**
    - Choose an S3 bucket name for storing files - this name must be _globally unique_ across all S3 buckets that exist on AWS. If you host Foundry on eg. `foundry.mydomain.com` then `foundry-mydomain-com` is a good recommendation

It should be pretty automated from there. Again, just be careful of the LetsEncrypt TLS issuance limits.

If need be, set the LetsEncrypt TLS testing option to `False` in the CloudFormation setup if you are debugging a failed stack deploy. Should you run out of LetsEncrypt TLS requests, you'll need to wait one week before trying again.

## Security and Updates

As of the `v1.1.0` release, Linux auto-patching is enabled by default. A utility script `utils/kernel_updates.sh` also exists to help you manage this if you want to disable or re-enable or run it.

It's also recommended to SSH into the instance and run `sudo dnf upgrade` every so often to make sure your packages are up to date with the latest fixes and security releases.

## Upgrading From a Previous Installation

see [Upgrading](docs/UPGRADING.md)

## IPv6 Support

see [IPv6](docs/IPv6.md)

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

### Future Considerations

- Improve CloudWatch logs (?)
- Add script to facilitate transfer between two EC2s?
- Store LetsEncrypt PEM keys in AWS Secrets Manager and retrieve them instead of requesting new ones to work around the issuance limit (is that even possible / supported?)
- Better ownership/permissions defaults?
- Automatically select the `x86_64` or `arm64` image based on instance choice (even possible?)
- Consider using SSH forwarding via SSM or EC2 Instance Connect instead of key pair stuff, would need to look into this
- IPv6 support (AWS will soon start charging for IPv4 address assignments), in progress

https://api.foundry.metalisticpain.com/start
https://api.foundry.metalisticpain.com/stop
https://api.foundry.metalisticpain.com/ip/add
https://api.foundry.metalisticpain.com/ip/reset