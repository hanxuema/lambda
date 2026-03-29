import logging
from database import execute_query, create_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info("Handling list_all_directors request")
        sql = """
            SELECT d.id, d.name, d.title, c.id as company_id, c.name as company_name 
            FROM director d
            JOIN company c ON d.company_id = c.id
            ORDER BY d.name ASC, c.name ASC
        """
        records = execute_query(sql)
        
        grouped = {}
        for r in records:
            name = r['name']
            if name not in grouped:
                grouped[name] = {"name": name, "roles": []}
            grouped[name]["roles"].append({
                "id": r['id'],
                "company_id": r['company_id'],
                "company_name": r['company_name'],
                "title": r['title']
            })
            
        result = list(grouped.values())
        return create_response(200, {'directors': result})
    except Exception as e:
        logger.error(f"Error in list_all_directors: {e}")
        return create_response(500, {'error': 'Failed to list directors', 'details': str(e)})
