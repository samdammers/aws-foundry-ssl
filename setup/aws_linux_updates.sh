#!/bin/bash

# ----------------------------------------------------
# Set up Amazon Linux kernel autopatching for security
# ----------------------------------------------------

# https://docs.aws.amazon.com/linux/al2023/ug/live-patching.html

dnf install -y kpatch-dnf
dnf kernel-livepatch -y auto

dnf install -y kpatch-runtime
dnf update kpatch-runtime

systemctl enable --now kpatch.service
