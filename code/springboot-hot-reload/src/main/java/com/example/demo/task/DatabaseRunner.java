package com.example.demo.task;

import com.example.demo.repository.CustomerRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class DatabaseRunner {
    private static final Logger log = LoggerFactory.getLogger(DatabaseRunner.class);
    
    private final CustomerRepository customerRepository;

    public DatabaseRunner(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }

    @Scheduled(fixedRate = 30_000)
    public void checkDatabase() {
        try {
            long count = customerRepository.count();
            log.info("DB connection OK — {} customers", count);
        } catch (Exception e) {
            log.error("DB connection FAILED: {}", e.getMessage());
        }
    }
}