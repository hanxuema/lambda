import logging
import json
import os
import boto3
import pg8000.native

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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
        logger.info(f"RDS Proxy Connection Demo - Handling get_company")
        
        path_parameters = event.get('pathParameters', {}) or {}
        company_id = path_parameters.get('id')
        if not company_id or not str(company_id).isdigit():
            return create_response(400, {'error': 'Invalid company ID'})

        secret_arn = os.environ['DB_SECRET_ARN']
        creds = get_db_credentials(secret_arn)
        
        # Connect via RDS Proxy
        conn = pg8000.native.Connection(
            user=creds['username'],
            password=creds['password'],
            host=os.environ['PROXY_ENDPOINT'],
            database=os.environ['DB_NAME'],
            port=5432
        )
        
        sql = "SELECT id, name, industry FROM company WHERE id = :cid"
        rows = conn.run(sql, cid=int(company_id))
        
        if not rows:
            conn.close()
            return create_response(404, {'error': 'Company not found'})
            
        company = {
            "id": rows[0][0],
            "name": rows[0][1],
            "industry": rows[0][2]
        }
            
        conn.close()
        return create_response(200, {'company': company, 'connection_mode': 'rds-proxy'})

    except Exception as e:
        logger.error(f"RDS Proxy Error: {e}")
        return create_response(500, {'error': 'Failed to list via Proxy', 'details': str(e)})

def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }
