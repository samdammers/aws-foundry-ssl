"""This script updates a bucket policy to append IP or reset them"""
import json
import os

import boto3

BUCKET_NAME = os.getenv("S3_BUCKET")


def reset_ip_list(s3_client):
    """
    Reset to original VPC subnet list
    :param s3_client:
    :return:
    """
    resp = s3_client.get_bucket_policy(Bucket=BUCKET_NAME)
    policy = json.loads(resp["Policy"])
    ip_list = policy.get("Statement")[0].get("Condition").get("IpAddress").get("aws:SourceIp")
    reset_list = [x for x in ip_list if x.startswith("172")]
    policy["Statement"][0]["Condition"]["IpAddress"]["aws:SourceIp"] = reset_list

    s3_client.put_bucket_policy(Bucket=BUCKET_NAME, Policy=json.dumps(policy))


def add_ip(s3_client, ip_address):
    """
    Add IP address to existing set

    :param s3_client:
    :param ip_address:
    :return:
    """
    resp = s3_client.get_bucket_policy(Bucket=BUCKET_NAME)
    policy = json.loads(resp["Policy"])

    # Append new item to list, convert to set then back to list to ensure unique values only
    unique_list = list(
        set(
            policy.get("Statement")[0]
            .get("Condition")
            .get("IpAddress")
            .get("aws:SourceIp")
            .append(f"{ip_address}/32")
        )
    )
    policy["Statement"][0]["Condition"]["IpAddress"]["aws:SourceIp"] = unique_list

    s3_client.put_bucket_policy(Bucket=BUCKET_NAME, Policy=json.dumps(policy))


def ec2_actions(ec2_client, action):
    """
    Either STOP or START EC2 Instance
    :param ec2_client:
    :param action:
    :return:
    """
    resp = ec2_client.describe_instances(
        Filters=[
            {
                "Name": "tag:service",
                "Values": [
                    "foundry",
                ],
            },
        ],
    )

    instance_id = resp.get("Reservations")[0].get("Instances")[0].get("InstanceId")

    if action == "STOP":
        ec2_client.stop_instances(InstanceIds=[instance_id])
        return

    if action == "START":
        ec2_client.start_instances(InstanceIds=[instance_id])
        return

    raise RuntimeError("Did not receive action of START|STOP")


def lambda_handler(event, context):
    # pylint: disable=unused-argument
    """ Lambda Handler, handles scheduled timer events and Cloudtrail CreateLogGroup events """

    sess = boto3.session.Session()
    detail_type = event.get("detail-type", "")
    route_key = event.get("routeKey", "")

    # Scheduled event - correct all existing loggroups subscriptions (add or remove)
    if detail_type == "Scheduled Event" or route_key == "GET /ip/reset":
        reset_ip_list(sess.client("s3"))
        return

    if route_key == "GET /ip/add":
        ip = event.get("headers").get("x-forwarded-for")
        add_ip(sess.client("s3"), ip)
        return

    if route_key == "GET /stop":
        ec2_actions(sess.client("ec2"), "STOP")

    if route_key == "GET /start":
        ec2_actions(sess.client("ec2"), "START")

    return
