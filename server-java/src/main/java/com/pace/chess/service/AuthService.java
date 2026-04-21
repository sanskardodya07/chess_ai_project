package com.pace.chess.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.Map;

@Service
public class AuthService {

    @Autowired RedisService redis;

    @Value("${jwt.secret}")
    private String jwtSecret;

    private static final long EXPIRY_MS = 30L * 24 * 60 * 60 * 1000;

    public boolean isValidUsername(String u) {
        return u != null && u.matches("[A-Za-z]{1,7}");
    }

    public boolean userExists(String username) {
        return redis.hget("user:" + username, "password") != null;
    }

    public void createUser(String username, String password) {
        String hash = BCrypt.hashpw(password, BCrypt.gensalt());
        redis.hset("user:" + username, Map.of(
            "password",     hash,
            "total_points", "0",
            "wins",         "0",
            "losses",       "0",
            "draws",        "0"
        ));
        redis.zadd("leaderboard", 0, username);
    }

    public boolean checkPassword(String password, String username) {
        String hash = redis.hget("user:" + username, "password");
        return hash != null && BCrypt.checkpw(password, hash);
    }

    public String createToken(String username) {
        return Jwts.builder()
            .setSubject(username)
            .setExpiration(new Date(System.currentTimeMillis() + EXPIRY_MS))
            .signWith(Keys.hmacShaKeyFor(jwtSecret.getBytes()))
            .compact();
    }

    public String verifyToken(String token) {
        try {
            return Jwts.parserBuilder()
                .setSigningKey(Keys.hmacShaKeyFor(jwtSecret.getBytes()))
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getSubject();
        } catch (Exception e) { return null; }
    }

    public Map<String, String> getUserStats(String username) {
        return redis.hgetAll("user:" + username);
    }
}