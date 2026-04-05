import json
import logging
from database import execute_query, create_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info(f"Handling update_director request with event: {event}")
        path_parameters = event.get('pathParameters', {}) or {}
        director_id = path_parameters.get('id')
        
        if not director_id or not str(director_id).isdigit():
            return create_response(400, {'error': 'Invalid director ID'})
            
        body = event.get('body')
        if not body:
            return create_response(400, {'error': 'Empty request body'})
            
        try:
            parsed_body = json.loads(body)
        except json.JSONDecodeError:
            return create_response(400, {'error': 'Invalid JSON in request body'})
            
        new_title = parsed_body.get('title')
        new_address = parsed_body.get('address')
        
        if not new_title and not new_address:
            return create_response(400, {'error': 'At least one field (title or address) is required'})
            
        # Dynamically build SQL to update only provided fields
        update_parts = []
        params = [{'name': 'id', 'value': {'longValue': int(director_id)}}]
        
        if new_title:
            update_parts.append("title = :title")
            params.append({'name': 'title', 'value': {'stringValue': new_title}})
        if new_address:
            update_parts.append("address = :address")
            params.append({'name': 'address', 'value': {'stringValue': new_address}})
            
        sql = f"UPDATE director SET {', '.join(update_parts)} WHERE id = :id RETURNING *"
        
        result = execute_query(sql, params)
        if not result:
            return create_response(404, {'error': 'Director not found'})
            
        return create_response(200, {'message': 'Director updated successfully', 'director': result[0]})
    except Exception as e:
        logger.error(f"Error in update_director: {e}")
        return create_response(500, {'error': 'Failed to update director', 'details': str(e)})
