import json
import boto3


def handler(event, context):
    client = boto3.client('lambda')
    event_body = json.loads(event['body'])
    response = client.invoke(
        FunctionName='TextRecognitionLambda',
        InvocationType='RequestResponse',
        Payload=json.dumps({'image': event_body['image']})
    )

    response_payload = json.loads(response['Payload'].read())
    return {
        'statusCode': response_payload['statusCode'],
        'body': response_payload['body']
    }
