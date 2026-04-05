import logging
import json
import os
import boto3
import pg8000.native

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Secrets Manager client
secrets_client = boto3.client('secretsmanager')

def get_db_credentials(secret_arn):
    try:
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        return json.loads(response['SecretString'])
    except Exception as e:
        logger.error(f"Error fetching secret: {e}")
        raise

def handler(event, context):
    try:
        logger.info(f"Traditional Connection Demo - Handling list_directors")
        
        # 1. Inputs
        path_parameters = event.get('pathParameters', {}) or {}
        company_id = path_parameters.get('id')
        if not company_id:
            return create_response(400, {'error': 'Missing company ID'})

        # 2. Get Credentials from Secrets Manager (VPC Endpoint usage)
        secret_arn = os.environ['DB_SECRET_ARN']
        creds = get_db_credentials(secret_arn)
        
        # 3. Establish TRADITIONAL TCP Connection (pg8000)
        # Note: This happens inside the VPC
        conn = pg8000.native.Connection(
            user=creds['username'],
            password=creds['password'],
            host=os.environ['DB_ENDPOINT'],
            database=os.environ['DB_NAME'],
            port=5432
        )
        
        # 4. Execute Query
        sql = "SELECT id, name, title, address, company_id FROM director WHERE company_id = :cid ORDER BY id ASC"
        # pg8000.native uses :name for parameters
        rows = conn.run(sql, cid=int(company_id))
        
        # 5. Transform rows to dict
        # rows format: [[id, name, title, address, company_id], ...]
        directors = []
        for r in rows:
            directors.append({
                "id": r[0],
                "name": r[1],
                "title": r[2],
                "address": r[3],
                "company_id": r[4]
            })
            
        conn.close()
        return create_response(200, {'directors': directors, 'connection_mode': 'traditional-tcp'})

    except Exception as e:
        logger.error(f"Traditional Connection Error: {e}")
        return create_response(500, {'error': 'Failed to list directors via TCP', 'details': str(e)})

def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }
