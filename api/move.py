import json

def handler(request):
    """Simple test handler to verify Vercel deployment works."""
    if request.method == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
        }

    if request.method != "POST":
        return {
            "statusCode": 405,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Method not allowed"})
        }

    try:
        # Just return a simple success response
        return {
            "statusCode": 200,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({
                "status": "ok",
                "message": "Vercel function is working!",
                "ai_move": {
                    "start": [6, 4],
                    "end": [4, 4],
                    "piece_moved": "wP",
                    "piece_captured": "",
                    "promotion": None,
                    "is_castle": False,
                    "is_en_passant": False,
                }
            })
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"status": "error", "message": str(e)})
        }

# Expose aliases for Vercel runtime compatibility
app = handler
application = handler
