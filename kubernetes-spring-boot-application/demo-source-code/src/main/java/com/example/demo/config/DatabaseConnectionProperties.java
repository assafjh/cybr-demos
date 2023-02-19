package com.example.demo.config;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class DatabaseConnectionProperties extends PropertyWatcher {

    @Value("${spring.datasource.username}")
    @Getter
    private String datasourceUsername;

    @Value("${spring.datasource.password}")
    @Getter
    private String datasourcePassword;

    private final HikariDataSource dataSource;

    public DatabaseConnectionProperties(HikariDataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    protected String getPropertyFileName() {
        return "database-configuration.properties";
    }

    @Override
    protected void actionsAfterReload() {
        updateKeys();
        refreshConnectionPool();
    }

    private void updateKeys() {
        this.datasourceUsername = environment.getProperty("spring.datasource.username");
        this.datasourcePassword = environment.getProperty("spring.datasource.password");
    }

    private void refreshConnectionPool() {
        dataSource.setUsername(datasourceUsername);
        dataSource.setPassword(datasourcePassword);
        HikariPoolMXBean hikariPoolMXBean = dataSource.getHikariPoolMXBean();
        hikariPoolMXBean.softEvictConnections();
        log.info("Refreshing database connection.");
    }

}
