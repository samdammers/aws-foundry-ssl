#!/bin/bash

# -----------------------
# Install nginx webserver
# -----------------------

if [[ ${webserver_bool} == "True" ]]; then
    foundry_file="foundryvtt_webserver.conf"
else
    foundry_file="foundryvtt.conf"
fi

# Install nginx
cp /aws-foundry-ssl/setup/nginx/nginx.repo /etc/yum.repos.d/nginx.repo
dnf config-manager --enable nginx-mainline
dnf install nginx --repo nginx-mainline -y

# Configure nginx
mkdir /var/log/nginx/foundry
cp /aws-foundry-ssl/setup/nginx/${foundry_file} /etc/nginx/conf.d/foundryvtt.conf
sed -i "s/YOURSUBDOMAINHERE/${subdomain}/g" /etc/nginx/conf.d/foundryvtt.conf
sed -i "s/YOURDOMAINHERE/${fqdn}/g" /etc/nginx/conf.d/foundryvtt.conf

# Start nginx
systemctl enable --now nginx

# Configure foundry for nginx
sed -i "s/\"hostname\":.*/\"hostname\": \"${subdomain}\.${fqdn}\",/g" /foundrydata/Config/options.json
sed -i 's/"proxyPort":.*/"proxyPort": "80",/g' /foundrydata/Config/options.json

# Setup webserver
if [[ ${webserver_bool} == "True" ]]; then
    # Copy webserver files
    git clone https://github.com/zkkng/foundry-website.git /foundry-website
    cp -rf /foundry-website/* /usr/share/nginx/html

    # Give ec2-user permissions
    chown ec2-user -R /usr/share/nginx/html
    chmod 755 -R /usr/share/nginx/html

    # Clean up install files
    rm -r /foundry-website
fi

systemctl restart nginx
