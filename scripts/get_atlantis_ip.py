#!/usr/bin/env python3
import time 
import sys
import json
import boto3

def main():
    time.sleep(90) #Sleep for a 90 seconds to make sure task has started and public IP could be retrieved successfully.
    
    # Read input from Terraform external data source
    input_data = json.load(sys.stdin)
    cluster = input_data.get("cluster")
    service = input_data.get("service")
    # Use provided region or default to us-east-1
    region = input_data.get("region", "us-east-1")
    
    ecs = boto3.client("ecs", region_name=region)
    tasks_response = ecs.list_tasks(cluster=cluster, serviceName=service, desiredStatus="RUNNING")
    task_arns = tasks_response.get("taskArns", [])
    
    # Return "PENDING" if no running task is found
    if not task_arns:
        print(json.dumps({"public_ip": "PENDING"}))
        sys.exit(0)
    
    # Use the first task ARN
    task_arn = task_arns[0]
    task_details = ecs.describe_tasks(cluster=cluster, tasks=[task_arn]).get("tasks", [])
    if not task_details:
        print(json.dumps({"public_ip": "PENDING"}))
        sys.exit(0)
    task = task_details[0]
    
    # Look for the network interface ID in the task attachments
    eni_id = None
    for attachment in task.get("attachments", []):
        for detail in attachment.get("details", []):
            if detail.get("name") == "networkInterfaceId":
                eni_id = detail.get("value")
                break
        if eni_id:
            break
    
    if not eni_id:
        print(json.dumps({"public_ip": "PENDING"}))
        sys.exit(0)
    
    ec2 = boto3.client("ec2", region_name=region)
    eni_response = ec2.describe_network_interfaces(NetworkInterfaceIds=[eni_id])
    enis = eni_response.get("NetworkInterfaces", [])
    if not enis:
        print(json.dumps({"public_ip": "PENDING"}))
        sys.exit(0)
    
    public_ip = enis[0].get("Association", {}).get("PublicIp", "")
    if not public_ip:
        public_ip = "PENDING"
    
    print(json.dumps({"public_ip": public_ip}))

if __name__ == "__main__":
    main()
