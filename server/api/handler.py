from api.deserializer import board_from_json
from api.serializer import move_to_json
from agent.reasoning.alpha_beta import get_best_move
import json

def handler(request):
    try:
        data = request.get_json()

        board_data = data["board"]
        depth = data.get("depth", 3)

        board = board_from_json(board_data)
        move = get_best_move(board, depth)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "move": move_to_json(move)
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }