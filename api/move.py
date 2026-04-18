import json

def handler(event, context):
    """Vercel serverless function handler."""
    try:
        # Handle CORS preflight
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type',
                },
                'body': ''
            }

        # Only allow POST requests
        if event.get('httpMethod') != 'POST':
            return {
                'statusCode': 405,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Method not allowed'})
            }

        # Return success response
        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'status': 'ok',
                'message': 'Vercel function is working!',
                'ai_move': {
                    'start': [6, 4],
                    'end': [4, 4],
                    'piece_moved': 'wP',
                    'piece_captured': '',
                    'promotion': None,
                    'is_castle': False,
                    'is_en_passant': False,
                }
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'status': 'error', 'message': str(e)})
        }
