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
        if not new_title:
            return create_response(400, {'error': 'Title field is required'})
            
        sql = 'UPDATE director SET title = :title WHERE id = :id RETURNING *'
        params = [
            {'name': 'title', 'value': {'stringValue': new_title}},
            {'name': 'id', 'value': {'longValue': int(director_id)}}
        ]
        
        result = execute_query(sql, params)
        if not result:
            return create_response(404, {'error': 'Director not found'})
            
        return create_response(200, {'message': 'Director updated successfully', 'director': result[0]})
    except Exception as e:
        logger.error(f"Error in update_director: {e}")
        return create_response(500, {'error': 'Failed to update director', 'details': str(e)})
