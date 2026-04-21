package com.pace.chess.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import redis.clients.jedis.*;

import jakarta.annotation.PostConstruct;
import java.net.URI;
import java.util.*;

@Service
public class RedisService {

    @Value("${redis.url}")
    private String redisUrl;

    private JedisPool pool;

    @PostConstruct
    public void init() {
        try {
            JedisPoolConfig cfg = new JedisPoolConfig();
            cfg.setMaxTotal(10);
            pool = new JedisPool(cfg, new URI(redisUrl));
        } catch (Exception e) {
            throw new RuntimeException("Redis init failed: " + e.getMessage());
        }
    }

    public String hget(String key, String field) {
        try (Jedis j = pool.getResource()) { return j.hget(key, field); }
    }

    public void hset(String key, Map<String, String> fields) {
        try (Jedis j = pool.getResource()) { j.hset(key, fields); }
    }

    public Map<String, String> hgetAll(String key) {
        try (Jedis j = pool.getResource()) { return j.hgetAll(key); }
    }

    public void hincrBy(String key, String field, long val) {
        try (Jedis j = pool.getResource()) { j.hincrBy(key, field, val); }
    }

    public void zadd(String key, double score, String member) {
        try (Jedis j = pool.getResource()) { j.zadd(key, score, member); }
    }

    public void zincrby(String key, double score, String member) {
        try (Jedis j = pool.getResource()) { j.zincrby(key, score, member); }
    }

    public long zcard(String key) {
        try (Jedis j = pool.getResource()) { return j.zcard(key); }
    }

    public List<Tuple> zrevrangeWithScores(String key, long start, long stop) {
        try (Jedis j = pool.getResource()) {
            return new ArrayList<>(j.zrevrangeWithScores(key, start, stop));
        }
    }

    // Atomic score update using pipeline
    public void updateScore(String username, long points, String result) {
        try (Jedis j = pool.getResource()) {
            Pipeline p = j.pipelined();
            p.hincrBy("user:" + username, "total_points", points);
            p.hincrBy("user:" + username, result,         1);
            p.zincrby("leaderboard", points, username);
            p.sync();
        }
    }
}