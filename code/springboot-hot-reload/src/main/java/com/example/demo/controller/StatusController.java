package com.example.demo.controller;

import com.example.demo.repository.CustomerRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class StatusController {

    private final CustomerRepository customerRepository;
    private final DataSource dataSource;

    public StatusController(CustomerRepository customerRepository, DataSource dataSource) {
        this.customerRepository = customerRepository;
        this.dataSource = dataSource;
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        Map<String, Object> body = new LinkedHashMap<>();
        try (Connection conn = dataSource.getConnection()) {
            body.put("status", "UP");
            body.put("user", conn.getMetaData().getUserName());
            body.put("customers", customerRepository.count());
        } catch (Exception e) {
            body.put("status", "DOWN");
            body.put("error", e.getMessage());
            return ResponseEntity.status(503).body(body);
        }
        return ResponseEntity.ok(body);
    }
}
