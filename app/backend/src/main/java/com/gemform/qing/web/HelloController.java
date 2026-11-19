package com.gemform.qing.web;

import java.time.OffsetDateTime;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HelloController {

    private final JdbcTemplate jdbcTemplate;

    public HelloController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/hello")
    public Map<String, Object> hello() {
        String version = jdbcTemplate.queryForObject(
                "select current_setting('server_version')", String.class);
        return Map.of(
                "message", "Hello from Qing",
                "database", "PostgreSQL " + version,
                "timestamp", OffsetDateTime.now().toString());
    }
}
