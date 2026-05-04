package com.example.demo;

import com.example.demo.repository.CustomerRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.context.refresh.ContextRefresher;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class HotReloadIntegrationTest {

    static Path credentialsFile;

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17-alpine")
            .withInitScript("test-schema.sql");

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        try {
            credentialsFile = Files.createTempFile("db-credentials", ".properties");
            writeCredentials(postgres.getUsername(), postgres.getPassword());

            registry.add("spring.datasource.url", postgres::getJdbcUrl);
            // Override the K8s-specific import path with our temp file
            registry.add("spring.config.import",
                    () -> "optional:file:" + credentialsFile.toAbsolutePath());
            // Point watcher at a non-existent path so it doesn't race with the test
            registry.add("secrets.watch-dir", () -> "/tmp/no-watch-in-test");
        } catch (IOException e) {
            throw new RuntimeException("Failed to set up credentials file for test", e);
        }
    }

    static void writeCredentials(String user, String password) throws IOException {
        Files.writeString(credentialsFile,
                "spring.datasource.username=" + user + "\n" +
                "spring.datasource.password=" + password + "\n");
    }

    @Autowired
    CustomerRepository customerRepository;

    @Autowired
    ContextRefresher contextRefresher;

    @Test
    void contextLoadsAndQueriesDatabase() {
        assertThat(customerRepository.count()).isEqualTo(3);
    }

    @Test
    void credentialRotationReconnectsTransparently() throws Exception {
        assertThat(customerRepository.count()).isEqualTo(3);

        String newPassword = "rotated_" + System.currentTimeMillis();

        // Rotate password in the DB — simulates what a DBA / Conjur rotation does
        postgres.execInContainer("psql",
                "-U", postgres.getUsername(),
                "-d", postgres.getDatabaseName(),
                "-c", "ALTER USER " + postgres.getUsername() + " WITH PASSWORD '" + newPassword + "';");

        // Update credentials file — simulates what the Conjur push-to-file sidecar does
        writeCredentials(postgres.getUsername(), newPassword);

        // Trigger Spring Cloud refresh — in production this is driven by SecretFileWatcher
        contextRefresher.refresh();

        // After refresh the DataSource is recreated; queries must succeed with new credentials
        assertThatCode(() -> customerRepository.count()).doesNotThrowAnyException();
    }
}
