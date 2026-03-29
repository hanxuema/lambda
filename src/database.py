import boto3
import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('rds-data', region_name=os.environ.get('AWS_REGION', 'ap-southeast-2'))

def execute_query(sql, parameters=None):
    if parameters is None:
        parameters = []
    
    params = {
        'secretArn': os.environ['DB_SECRET_ARN'],
        'resourceArn': os.environ['DB_CLUSTER_ARN'],
        'database': os.environ['DB_NAME'],
        'sql': sql,
        'parameters': parameters,
        'formatRecordsAs': 'JSON'
    }
    
    try:
        response = client.execute_statement(**params)
        if 'formattedRecords' in response:
            return json.loads(response['formattedRecords'])
        return []
    except Exception as e:
        logger.error(f"Database error: {e}")
        raise

def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }
