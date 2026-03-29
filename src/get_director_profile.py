import logging
from urllib.parse import unquote
from database import execute_query, create_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        raw_name = event.get('pathParameters', {}).get('name')
        if not raw_name:
            return create_response(400, {'error': 'Missing director name in path'})
            
        name = unquote(raw_name)
        logger.info(f"Handling get_director_profile request for: {name}")
        
        sql = """
            SELECT d.id, d.name, d.title, c.id as company_id, c.name as company_name 
            FROM director d
            JOIN company c ON d.company_id = c.id
            WHERE d.name = :name
            ORDER BY c.name ASC
        """
        params = [{'name': 'name', 'value': {'stringValue': name}}]
        records = execute_query(sql, params)
        
        if not records:
            return create_response(404, {'error': 'Director not found'})
            
        profile = {
            "name": name,
            "roles": []
        }
        for r in records:
            profile["roles"].append({
                "id": r['id'],
                "company_id": r['company_id'],
                "company_name": r['company_name'],
                "title": r['title']
            })
            
        return create_response(200, {'profile': profile})
    except Exception as e:
        logger.error(f"Error in get_director_profile: {e}")
        return create_response(500, {'error': 'Failed to fetch director profile', 'details': str(e)})
