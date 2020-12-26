#!/bin/bash

# Generate keypair
aws ec2 create-key-pair --key-name Foundry --query 'KeyMaterial' --output text > ./Foundry.pem