package com.example.demo.bl;

import com.example.demo.config.DatabaseConnectionProperties;
import com.example.demo.repository.ZooRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class DatabaseRunner {

    private final ZooRepository zooRepository;
    private final DatabaseConnectionProperties databaseConnectionProperties;

    public DatabaseRunner(ZooRepository zooRepository, DatabaseConnectionProperties databaseConnectionProperties) {
        this.zooRepository = zooRepository;
        this.databaseConnectionProperties = databaseConnectionProperties;
    }

    @Scheduled(fixedRate = 10000)
    private void queryDataBase() {
        log.info("-------+-------------------------+---------------------+-----------------------------");
        log.info("Connecting to database using the following credentials:");
        log.info("Username: " + databaseConnectionProperties.getDatasourceUsername());
        log.info("Password: " + databaseConnectionProperties.getDatasourcePassword());
        log.info("-------+-------------------------+---------------------+-----------------------------");
        log.info("| id   |         type            |       caregiver     |           email            |");
        log.info("-------+-------------------------+---------------------+-----------------------------");
        try {
            zooRepository.findAll().forEach(animal -> log.info(String.format("| %4d | %-23s | %-19s | %-26s |", animal.getId(), animal.getType(), animal.getCaregiver(), animal.getEmail())));
        } catch (Exception ex) {
            log.error("Not able to create database connection.");
            log.error(ex.getMessage());
        }
        log.info("-------+-------------------------+---------------------+-----------------------------");
        log.info("Sleeping for 10 seconds before running the query again");
    }

}
