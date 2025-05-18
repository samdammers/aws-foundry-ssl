#!/bin/bash

# These files are created in the CloudFormation script
source /foundryssl/variables.sh
source /foundryssl/variables_tmp.sh

# Set up logging to the logfile
exec >> /tmp/foundry-setup.log 2>&1
set -x

# Install foundry
echo "===== 1. INSTALLING DEPENDENCIES ====="
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs
sudo dnf install -y openssl-devel
sudo dnf install -y amazon-cloudwatch-agent

# Install foundry
echo "===== 2. INSTALLING FOUNDRY ====="
source /aws-foundry-ssl/setup/foundry.sh

# Install nginx
echo "===== 3. INSTALLING NGINX ====="
source /aws-foundry-ssl/setup/nginx.sh

# Amazon Cloudwatch logs, zone updates and kernel patching
echo "===== 4. INSTALLING AWS SERVICES AND LINUX KERNEL PATCHING ====="
source /aws-foundry-ssl/setup/aws_cloudwatch_config.sh
source /aws-foundry-ssl/setup/aws_hosted_zone_ip.sh
source /aws-foundry-ssl/setup/aws_linux_updates.sh

# Set up TLS certificates with LetsEncrypt
echo "===== 5. INSTALLING LETSENCRYPT CERTBOT ====="
source /aws-foundry-ssl/setup/certbot.sh

# Restart Foundry so aws-s3.json is fully loaded
echo "===== 6. RESTARTING FOUNDRY ====="
systemctl restart foundry

# Clean up install files (Comment out during testing)
echo "===== 7. CLEANUP AND USER PERMISSIONS ====="
usermod -a -G foundry ec2-user
chown ec2-user -R /aws-foundry-ssl

chmod 744 /aws-foundry-ssl/utils/*.sh
chmod 700 /tmp/foundry-setup.log
rm /foundryssl/variables_tmp.sh

# Uncomment only if you really care to:
# rm -rf /aws-foundry-ssl

echo "===== 8. DONE ====="
echo "Finished setting up Foundry!"
