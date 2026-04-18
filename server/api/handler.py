from api.deserializer import board_from_json
from api.serializer import move_to_json
from agent.reasoning.alpha_beta import get_best_move


def handler(request):

    try:
        data = request.json()
        depth = int(data.get("depth", 3))

        if depth < 1 or depth > 5:
            depth = 3

        board = board_from_json(data)
        move = get_best_move(board, depth)

        if not move:
            return {"error": "no move returned"}

        return {
            "move": move_to_json(move),
            "depth": depth
        }

    except Exception as e:
        return {"error": str(e)}