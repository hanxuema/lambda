import logging
from database import execute_query, create_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info(f"Handling get_company request with event: {event}")
        path_parameters = event.get('pathParameters', {}) or {}
        company_id = path_parameters.get('id')
        
        if not company_id or not str(company_id).isdigit():
            return create_response(400, {'error': 'Invalid company ID'})
        
        sql = 'SELECT * FROM company WHERE id = :id'
        params = [{'name': 'id', 'value': {'longValue': int(company_id)}}]
        
        result = execute_query(sql, params)
        if not result:
            return create_response(404, {'error': 'Company not found'})
            
        return create_response(200, {'company': result[0]})
    except Exception as e:
        logger.error(f"Error in get_company: {e}")
        return create_response(500, {'error': 'Failed to get company', 'details': str(e)})
