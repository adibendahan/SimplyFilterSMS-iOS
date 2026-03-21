import json
import boto3
import uuid
import time

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('reported_messages')

MAX_BODIES = 5
MAX_STRING_LENGTH = 500
VALID_TYPES = {'deny', 'allow'}

def lambda_handler(event, context):
    print("REQUEST:", json.dumps(event))

    sender = str(event.get('sender', ''))[:MAX_STRING_LENGTH]
    report_type = str(event.get('type', ''))

    if report_type not in VALID_TYPES:
        print(f"REJECTED: invalid type '{report_type}'")
        return {'statusCode': 200}

    if 'bodies' in event:
        bodies = event['bodies']
    elif 'body' in event:
        bodies = [event['body']]
    else:
        bodies = []

    if not isinstance(bodies, list):
        print("REJECTED: bodies is not a list")
        return {'statusCode': 200}

    bodies = [str(b)[:MAX_STRING_LENGTH] for b in bodies[:MAX_BODIES] if str(b).strip()]

    if not bodies:
        print("REJECTED: no valid bodies")
        return {'statusCode': 200}

    for body in bodies:
        table.put_item(Item={
            'uuid': str(uuid.uuid4()),
            'timestamp': str(int(time.time() * 1000)),
            'sender': sender,
            'body': body,
            'type': report_type
        })

    return {'statusCode': 200}
