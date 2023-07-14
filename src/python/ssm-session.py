#!python3

import boto3
import sys
import argparse
import re
import os

def valid_ec2_region(region):
    ec2_regions = boto3.Session().get_available_regions('ec2')
    if region not in ec2_regions:
        raise argparse.ArgumentTypeError(f'{region} is not a valid EC2 region. Valid regions are: {ec2_regions}')
    return region

parser = argparse.ArgumentParser()
parser.description = 'Search for an EC2 instance by name or instance-id and start a session'
parser.add_help = True
parser.add_argument('-r', '--region', help='region to search for instance in', type=valid_ec2_region)
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-n', '--name', help='search for instance by name')
group.add_argument('-i', '--instance-id', help='search for instance by instance-id')
args = vars(parser.parse_args())

if args['region'] != None:
  regions = [args['region']]
else:
  regions = [
      'us-west-2',
      'ca-central-1',
      'ap-southeast-2',
      'eu-west-2',
  ]
  print(f'No region specified, searching in {regions}')

def find_instance_by_id(instanceId):
    results = []
    for region in regions:
        ec2 = boto3.client('ec2', region_name=region)
        try:
            result = ec2.describe_instances(InstanceIds=[instanceId])
            if result['Reservations']:
                results.append(result)
        except Exception as e:
            if e.response['Error']['Code'] != 'InvalidInstanceID.NotFound':
                raise
    return results

def running_instance_info(instance_arn):
    # parse region from instance_arn
    region = instance_arn.split(':')[3]
    instanceId = instance_arn.split('/')[1]
    
    ec2 = boto3.client('ec2', region_name=region)
    result = ec2.describe_instances(
        InstanceIds=[instanceId],
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['running']
            }
        ]
    )
    if result['Reservations']:
        return result['Reservations'][0]['Instances'][0]
    return None  

def find_instance_by_name(name):
    # using resourcegroupstaggingapi, for each region
    # find all instances with tag:Name = name
    # return the first one found
    results = []
    for region in regions:
        rgt = boto3.client('resourcegroupstaggingapi', region_name=region)
        result = rgt.get_resources(
            ResourceTypeFilters=["ec2:instance"],
            TagFilters=[
                {
                    'Key': 'Name',
                    'Values': [name]
                }
            ]
        )
        if result['ResourceTagMappingList']:
            for i in result['ResourceTagMappingList']:
                results.append(i['ResourceARN'])
    
    return [i for i in [running_instance_info(result) for result in results] if i != None]

result = []

if args['name']:
    result = find_instance_by_name(args['name'])
elif args['instance_id']:
    result = find_instance_by_id(args['instance_id'])
else:
    raise Exception('No name or instance-id specified')

def instance_string(instance):
    tag_string = ', '.join([f"{tag['Key']}={tag['Value']}" for tag in sorted(instance['Tags'], key=lambda x: x['Key']) if not re.search("^(aws:|AmazonECSManaged)", tag['Key'])])
    return f"  {instance['InstanceId']} | {tag_string}"


if len(result) == 0:
    raise Exception('No matching instances found')
elif len(result) > 1:
    print("More than one matching instance found, please specify instance-id")
    for i in result:
        print("  " + instance_string(i))
    exit(1)
else:
    result = result[0]

print("Starting session for:")
print("  " + instance_string(result))

cmd = ['aws', 'ssm', 'start-session', '--region', result['Placement']['AvailabilityZone'][:-1], '--target', result['InstanceId']]
print(f'> {" ".join(cmd)}')

os.execvp(cmd[0], cmd)
