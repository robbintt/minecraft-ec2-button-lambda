''' Flask service to provide webpage

consider async await with flask -- no idea about support...

    # can dispatch a an email with SNS if it's running for more than a day
    # would still be nice to get a user count somehow before stopping
    # the instance does tell the minecraft client user count so maybe it has an api...
    # the api would have to be at the game port though.... ... hmmm...
'''
import json
from flask import Flask, jsonify
import boto3
import aws_secrets
from datetime import date, datetime

app = Flask(__name__)

client = boto3.client(
    'ec2',
    aws_access_key_id=aws_secrets.aws_access_key_id,
    aws_secret_access_key=aws_secrets.aws_secret_access_key,
    region_name=aws_secrets.region_name)

minecraft_instance_ids = [aws_secrets.instance_id]

def json_serial(obj):
    '''JSON serializer for objects not serializable by default json code
    common solution from: https://stackoverflow.com/a/22238613
    '''
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError ("Type %s not serializable" % type(obj))


def stop_ec2_instance(instance_ids, dry_run, hibernate):
    ''' Hibernate a given instance unless explicitly stopped.

    Only AMIs support hibernation... the current machine is ubuntu.

    I was planning to switch to AMI, but haven't really messed with it.

    Apparently after 60 days you need to hard stop and hard start it.
    I don't know how that works, but eh... something to read up on.
    '''
    stop_response = client.stop_instances(
            InstanceIds=instance_ids,
            Hibernate=hibernate,
            DryRun=dry_run
            )

    return stop_response 

def describe_ec2_instance(instance_ids, dry_run):
    ''' Describe an ec2 instance
    '''
    describe_response = client.describe_instances(
            InstanceIds=instance_ids,
            DryRun=dry_run
            )

    return describe_response

def start_ec2_instance(instance_ids, dry_run, addl_info=''):
    ''' Start the ec2 instance

    documentation: 
        - https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html#EC2.Client.start_instances
    '''

    start_response = client.start_instances(
            InstanceIds=instance_ids,
            AdditionalInfo=addl_info,
            DryRun=dry_run
            )

    return start_response


@app.route('/start/', methods=["GET", "POST"])
def start_webpage():
    ''' start the ec2 instance on page load
    this probably needs some sort of authentication
    otherwise any bots that hit the URL will load it

    i could just use the endpoint as validation, e.g. put a UUID in the route

    then i could even rotate UUIDs if there's an issue

    Consider polling the instance to see its state.

    call describe before start and use a condition to start or stop?
    '''
    describe_response = describe_ec2_instance(minecraft_instance_ids, dry_run=False)
    start_response = start_ec2_instance(minecraft_instance_ids, dry_run=False)

    return json.dumps([start_response, describe_response], default=json_serial)


@app.route('/stop/', methods=["GET", "POST"])
def stop_webpage():
    ''' start the ec2 instance on page load
    this probably needs some sort of authentication
    otherwise any bots that hit the URL will load it

    i could just use the endpoint as validation, e.g. put a UUID in the route

    then i could even rotate UUIDs if there's an issue
    '''
    describe_response = describe_ec2_instance(minecraft_instance_ids, dry_run=False)
    stop_response = stop_ec2_instance(minecraft_instance_ids, dry_run=False, hibernate=False)

    return json.dumps([stop_response, describe_response], default=json_serial)


if __name__ == '__main__':
    app.run(debug=True)
