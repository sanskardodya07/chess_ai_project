import json

def handler(event, context):
    """Minimal Vercel Python function that works."""
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'message': 'Function works!',
            'ai_move': {
                'start': [6, 4],
                'end': [4, 4],
                'piece_moved': 'wP'
            }
        })
    }
