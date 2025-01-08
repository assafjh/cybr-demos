package com.cyberark.conjur.demo.controller;

import com.cyberark.conjur.demo.config.AppConfig;
import com.cyberark.conjur.demo.util.JwtUtil;
import com.cyberark.springboot.conjur.ConjurClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@Slf4j
public class SecretController {

<<<<<<< HEAD
    private final AppConfig appConfig; // AppConfig for configuration
    private final Environment environment; // Spring environment for profiles

    @GetMapping("/secret")
    public String getSecret() {
        log.info("Starting JWT generation and secret retrieval process");
=======
    private final AppConfig appConfig; // Injected AppConfig for configurations
    private final Environment environment; // For active profiles
    private final ConjurClient conjurClient; // Injected ConjurClient for SDK integration

    @GetMapping("/secret")
    public String getSecret() {
        log.info("Fetching secret using Conjur Spring Boot SDK");
>>>>>>> d98950cfea16f019d4c8dfb991cf693ba52ac46c

        // Get the JWKS file path from AppConfig
        String jwksFilePath = appConfig.getJwksFilePath();

        // Check if we are running in 'init' mode
        String initMode = System.getProperty("mode");
        if ("init".equalsIgnoreCase(initMode)) {
            try {
                // Generate and save the JWKS file
                JwtUtil.generateAndSaveJWKS(jwksFilePath);
                log.info("JWKS generated and saved at {}", jwksFilePath);
                return "JWKS generated successfully!";
            } catch (Exception e) {
                log.error("Error generating JWKS: ", e);
                return "Error occurred while generating JWKS.";
            }
        }

        // Fetch active profile
        String[] activeProfiles = environment.getActiveProfiles();
        String profile = activeProfiles.length > 0 ? activeProfiles[0] : "default";

<<<<<<< HEAD
        String subject = "spring-demo-app-" + profile;

        // Custom claims for the JWT
        Map<String, Object> claims = new HashMap<>();
        claims.put("profile", profile);

        try {
            // Generate JWT using JWKS
            String jwt = JwtUtil.generateJwt(subject, claims, jwksFilePath);
            log.debug("Generated JWT: {}", jwt);

            // Fetch the secret using ConjurSecret.retrieve()
            String secretPath = appConfig.getSecrets().get("my-secret");
            log.info("Retrieving secret from Conjur for path: {}", secretPath);
            String secret = ConjurSecret.retrieve(secretPath, jwt);
=======
        // Fetch the secret path from AppConfig
        String secretPath = appConfig.getSecrets().get("my-secret");

        try {
            // Retrieve the secret using ConjurClient
            String secret = conjurClient.getSecretsApi().getSecret(secretPath);
>>>>>>> d98950cfea16f019d4c8dfb991cf693ba52ac46c

            log.info("Successfully retrieved secret for profile: {}", profile);
            return "The secret is: " + secret;

        } catch (Exception e) {
            log.error("Error while fetching secret from Conjur", e);
            return "Error occurred while fetching the secret.";
        }
    }
}
