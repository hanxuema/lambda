import logging
from database import execute_query, create_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info(f"Handling list_directors request with event: {event}")
        path_parameters = event.get('pathParameters', {}) or {}
        company_id = path_parameters.get('id')
        
        if not company_id or not str(company_id).isdigit():
            return create_response(400, {'error': 'Invalid company ID'})
            
        sql = 'SELECT * FROM director WHERE company_id = :id ORDER BY id ASC'
        params = [{'name': 'id', 'value': {'longValue': int(company_id)}}]
        
        result = execute_query(sql, params)
        return create_response(200, {'directors': result})
    except Exception as e:
        logger.error(f"Error in list_directors: {e}")
        return create_response(500, {'error': 'Failed to list directors', 'details': str(e)})
