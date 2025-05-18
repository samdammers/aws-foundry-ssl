# IPv6 support

This currently relies on your default VPC. If you want to use IPv6 but haven't configured your VPC to support it, you'll need to manually make the following changes for now:

- **VPC**: Add a new IPv6 CIDR (Amazon-provided)
- **Subnets**
  - **CIDR Range**: Pick each subnet and edit its IPv6 CIDRs. Each should end in a unique incrementing number starting at 0 for the first, 1 for the second, etc. in any order. For example: `1234:5678:90a:bc00::/64`, `1234:5678:90a:bc01::/64`, `1234:5678:90a:bc02::/64`...
  - **Assign IPv6**: Choose a single subnet, then Edit subnet settings. Turn on `Enable auto-assign IPv6 address`. You likely also want to change `Hostname type` from `IP name` to `Resource name`. Also make this change for each of your subnets in the VPC
- **Route Tables**: Add a new route for `::/0`, pointed to your Internet Gateway (use the `0.0.0.0/0` entry as a reference)

Then deploy Foundry using this script. It should be assigned both an IPv4 and IPv6 address. Route53 via the AWS CLI is called by a `systemd` timer to add both the `A` and/or `AAAA` routing entries shortly after the server boots up.

### Uplifting an Existing Deploy

If you've already deployed Foundry, it's possible to uplift it to IPv6. After editing your VPC, subnets and route table, you also need to edit the EC2 Security Group's Incoming rules to add `::/0` for the HTTP, HTTPS, and custom port ranges in the Inbound rules (_except_ for `30000`). Then check the EC2's Network settings and auto-assign an IPv6 address to it.

Once AWS is configured, you'll need to edit the nginx configuration to listen to `[::]:80` and `[::]:443` traffic, which is a pass-through for IPv6 addresses. Check the base configuration file in this repository for reference.

Finally, you'll need to add an `AAAA` record to your domain name in Route 53, pointing it to the IPv6 address of the EC2.

### IPv6 Only

IPv6 _only_ is certainly possible, however this needs further work before it's available. It's important as Amazon charges for IPv4 addresses.
