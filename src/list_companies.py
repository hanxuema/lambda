import logging
from database import execute_query, create_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info("Handling list_companies request")
        result = execute_query('SELECT * FROM company ORDER BY id ASC')
        return create_response(200, {'companies': result})
    except Exception as e:
        logger.error(f"Error in list_companies: {e}")
        return create_response(500, {'error': 'Failed to list companies', 'details': str(e)})
