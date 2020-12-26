"""This script updates a bucket policy to append IP or reset them"""
import sys
import logging
import json
import boto3
import os
import string


def main():
    sess = boto3.session.Session()
    s3_client = sess.client("s3")

    resp = s3_client.get_bucket_policy(Bucket="foundry-vtt-server-dammers")
    policy = json.loads(resp["Policy"])

    ip_list = policy.get("Statement")[0].get("Condition").get("IpAddress").get("aws:SourceIp")

    print(ip_list)
    ip_list.append("115.64.140.171/32")
    

    reset_list = [x for x in ip_list if x.startswith('172')]


    print(reset_list)
    print(policy)

if __name__ == "__main__":
    main()