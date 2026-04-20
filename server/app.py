import sys, os, asyncio, logging, re, math
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(__file__))

import bcrypt
import jwt
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from upstash_redis import Redis

from api.deserializer import board_from_json
from api.serializer import move_to_json
from agent.reasoning.alpha_beta import get_best_move

# ── Setup ─────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("PACE")

redis = Redis(
    url=os.environ["KV_REST_API_URL"],
    token=os.environ["KV_REST_API_TOKEN"]
)

JWT_SECRET = os.environ.get("JWT_SECRET", "pace-chess-secret-change-this")
JWT_EXPIRY_DAYS = 30

request_log = []
MAX_LOG = 20

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Helpers ───────────────────────────────────────────
def log_entry(entry):
    request_log.insert(0, entry)
    if len(request_log) > MAX_LOG:
        request_log.pop()

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def check_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())

def create_token(username: str) -> str:
    payload = {
        "sub": username,
        "exp": datetime.utcnow() + timedelta(days=JWT_EXPIRY_DAYS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")

def verify_token(token: str):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload["sub"]
    except Exception:
        return None

def is_valid_username(username: str) -> bool:
    return bool(re.fullmatch(r"[A-Za-z]{1,7}", username))

# ── Auth endpoints ────────────────────────────────────
@app.post("/api/auth/register")
async def register(request: Request):
    body = await request.json()
    username = body.get("username", "").strip()
    password = body.get("password", "").strip()

    if not username or not password:
        return JSONResponse(status_code=400,
            content={"error": "Username and password required"})

    if not is_valid_username(username):
        return JSONResponse(status_code=400,
            content={"error": "Username must be 1-7 letters only"})

    if len(password) < 4:
        return JSONResponse(status_code=400,
            content={"error": "Password must be at least 4 characters"})

    existing = redis.hget(f"user:{username}", "password")
    if existing:
        return JSONResponse(status_code=409,
            content={"error": "Username already taken"})

    redis.hset(f"user:{username}", mapping={
        "password":     hash_password(password),
        "total_points": 0,
        "wins":         0,
        "losses":       0,
        "draws":        0,
    })

    # Add to leaderboard sorted set with score 0
    redis.zadd("leaderboard", {username: 0})

    token = create_token(username)
    logger.info(f"New user registered: {username}")
    return {"token": token, "username": username}


@app.post("/api/auth/login")
async def login(request: Request):
    body = await request.json()
    username = body.get("username", "").strip()
    password = body.get("password", "").strip()

    stored_hash = redis.hget(f"user:{username}", "password")
    if not stored_hash or not check_password(password, stored_hash):
        return JSONResponse(status_code=401,
            content={"error": "Invalid username or password"})

    token = create_token(username)
    stats = redis.hgetall(f"user:{username}")
    logger.info(f"User logged in: {username}")
    return {
        "token":        token,
        "username":     username,
        "total_points": int(stats.get("total_points", 0)),
        "wins":         int(stats.get("wins", 0)),
        "losses":       int(stats.get("losses", 0)),
        "draws":        int(stats.get("draws", 0)),
    }


# ── Score endpoint ────────────────────────────────────
@app.post("/api/score/update")
async def update_score(request: Request):
    auth = request.headers.get("Authorization", "")
    token = auth.replace("Bearer ", "").strip()
    username = verify_token(token)

    if not username:
        return JSONResponse(status_code=401,
            content={"error": "Invalid or expired token"})

    body        = await request.json()
    result      = body.get("result")        # "win" | "loss" | "draw"
    margin      = body.get("margin", 0)     # material advantage at game end

    if result not in ("win", "loss", "draw"):
        return JSONResponse(status_code=400,
            content={"error": "result must be win/loss/draw"})

    points_earned = 0
    if result == "win":
        bonus         = math.ceil(max(margin, 0) / 2)
        points_earned = 1 + bonus

    pipe = redis.pipeline()
    pipe.hincrby(f"user:{username}", "total_points", points_earned)
    pipe.hincrby(f"user:{username}", "wins",   1 if result == "win"  else 0)
    pipe.hincrby(f"user:{username}", "losses", 1 if result == "loss" else 0)
    pipe.hincrby(f"user:{username}", "draws",  1 if result == "draw" else 0)
    pipe.zincrby("leaderboard", points_earned, username)
    pipe.execute()

    new_total = int(redis.hget(f"user:{username}", "total_points") or 0)
    logger.info(f"Score updated: {username} +{points_earned} pts ({result})")
    return {"points_earned": points_earned, "total_points": new_total}


# ── Leaderboard endpoint ──────────────────────────────
@app.get("/api/leaderboard")
async def leaderboard():
    # Top 10 descending
    entries = redis.zrange("leaderboard", 0, 9,
                           rev=True, withscores=True)
    board = []
    for i, (username, score) in enumerate(entries):
        board.append({
            "rank":     i + 1,
            "username": username,
            "points":   int(score),
        })
    return {"leaderboard": board}


# ── Move endpoint ─────────────────────────────────────
@app.post("/api/move")
async def get_move(request: Request):
    received_at = datetime.utcnow().strftime("%H:%M:%S UTC")
    body       = await request.json()
    depth      = body.get("depth", 3)
    board_data = body["board"]
    turn       = board_data.get("turn", "?")

    logger.info(f"[{received_at}] Move | turn={turn} depth={depth}")

    try:
        loop = asyncio.get_event_loop()
        move = await asyncio.wait_for(
            loop.run_in_executor(
                None,
                lambda: get_best_move(board_from_json(board_data), depth)
            ),
            timeout=8.0
        )
    except asyncio.TimeoutError:
        logger.warning(f"[{received_at}] Timeout — retrying depth 2")
        try:
            loop = asyncio.get_event_loop()
            move = await asyncio.wait_for(
                loop.run_in_executor(
                    None,
                    lambda: get_best_move(board_from_json(board_data), 2)
                ),
                timeout=5.0
            )
        except asyncio.TimeoutError:
            return JSONResponse(status_code=504,
                content={"error": "Engine timeout"})

    result = move_to_json(move)
    log_entry({
        "time":   received_at,
        "turn":   turn,
        "depth":  depth,
        "status": "ok",
        "move":   f"{result['pieceMoved']} → ({result['endRow']},{result['endCol']})"
    })
    return {"move": result}


# ── Health ────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "engine": "PACE Alpha-Beta"}


# ── Dashboard ─────────────────────────────────────────
@app.get("/", response_class=HTMLResponse)
async def dashboard():
    try:
        total_users = redis.zcard("leaderboard")
        top = redis.zrange("leaderboard", 0, 4, rev=True, withscores=True)
        top_rows = "".join(
            f"<tr><td>#{i+1}</td><td>{u}</td><td style='color:#4A90D9'>{int(s)}</td></tr>"
            for i, (u, s) in enumerate(top)
        ) or "<tr><td colspan='3' style='color:#555;text-align:center'>No players yet</td></tr>"
    except Exception:
        total_users = "?"
        top_rows = "<tr><td colspan='3' style='color:#555;text-align:center'>DB unavailable</td></tr>"

    log_rows = "".join(
        f"<tr><td>{e['time']}</td><td>{e['turn']}</td><td>{e['depth']}</td>"
        f"<td style='color:{'#4CAF50' if e['status']=='ok' else '#FF9800'}'>{e['status']}</td>"
        f"<td>{e['move'] or '—'}</td></tr>"
        for e in request_log
    ) or "<tr><td colspan='5' style='color:#555;text-align:center;padding:24px'>No requests yet</td></tr>"

    return f"""<!DOCTYPE html><html><head><title>PACE Server</title>
    <meta http-equiv="refresh" content="5">
    <style>
      *{{box-sizing:border-box;margin:0;padding:0}}
      body{{background:#0f0f0f;color:#e0e0e0;font-family:'Courier New',monospace;padding:32px}}
      h1{{font-size:22px;font-weight:600;letter-spacing:2px;color:#fff}}
      .sub{{color:#555;font-size:12px;margin-top:4px}}
      .dot{{width:10px;height:10px;border-radius:50%;background:#4CAF50;
            animation:pulse 2s infinite;display:inline-block;margin-right:10px}}
      @keyframes pulse{{0%,100%{{opacity:1}}50%{{opacity:.4}}}}
      .grid{{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:28px 0}}
      .card{{background:#1a1a1a;border:1px solid #222;border-radius:10px;padding:20px}}
      .card h2{{font-size:11px;letter-spacing:1px;color:#555;text-transform:uppercase;margin-bottom:14px}}
      .stat{{font-size:32px;font-weight:700;color:#4A90D9}}
      table{{width:100%;border-collapse:collapse}}
      th{{background:#141414;padding:10px 14px;text-align:left;font-size:11px;
          letter-spacing:1px;color:#555;text-transform:uppercase}}
      td{{padding:10px 14px;border-top:1px solid #1e1e1e;font-size:13px;color:#ccc}}
      tr:hover td{{background:#1e1e1e}}
      .badge{{background:#1a1a1a;border:1px solid #2a2a2a;border-radius:6px;
              padding:3px 10px;font-size:11px;color:#4A90D9;margin-left:12px}}
    </style></head><body>
    <div style="display:flex;align-items:center;margin-bottom:28px;
                border-bottom:1px solid #222;padding-bottom:20px">
      <span class="dot"></span>
      <div><h1>PACE Server Dashboard<span class="badge">v1.0</span></h1>
      <div class="sub">Portable Application Chess Engine · Auto-refreshes every 5s</div></div>
    </div>
    <div class="grid">
      <div class="card">
        <h2>Registered Players</h2>
        <div class="stat">{total_users}</div>
      </div>
      <div class="card">
        <h2>Requests This Session</h2>
        <div class="stat">{len(request_log)}</div>
      </div>
    </div>
    <div class="grid">
      <div class="card">
        <h2>Top 5 Leaderboard</h2>
        <table><thead><tr><th>Rank</th><th>Player</th><th>Points</th></tr></thead>
        <tbody>{top_rows}</tbody></table>
      </div>
      <div class="card">
        <h2>Recent Move Requests</h2>
        <table><thead><tr><th>Time</th><th>Turn</th><th>Depth</th>
        <th>Status</th><th>Move</th></tr></thead>
        <tbody>{log_rows}</tbody></table>
      </div>
    </div>
    </body></html>"""