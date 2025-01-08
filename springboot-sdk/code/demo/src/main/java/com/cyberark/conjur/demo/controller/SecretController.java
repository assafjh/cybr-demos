package com.cyberark.conjur.demo.controller;

import com.cyberark.conjur.demo.config.AppConfig;
import com.cyberark.conjur.demo.util.JwtUtil;
import com.cyberark.springboot.conjur.api.ConjurClient;
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

    private final AppConfig appConfig;
    private final Environment environment;
    private final ConjurClient conjurClient; // Injected ConjurClient from the SDK

    @GetMapping("/secret")
    public String getSecret() {
        log.info("Starting secret retrieval process");

        // Get JWKS file path
        String jwksFilePath = appConfig.getJwksFilePath();

        // Check for 'init' mode
        String initMode = System.getProperty("mode");
        if ("init".equalsIgnoreCase(initMode)) {
            try {
                JwtUtil.generateAndSaveJWKS(jwksFilePath);
                log.info("JWKS generated and saved at {}", jwksFilePath);
                return "JWKS generated successfully!";
            } catch (Exception e) {
                log.error("Error generating JWKS: ", e);
                return "Error occurred while generating JWKS.";
            }
        }

        // Retrieve active profile
        String[] activeProfiles = environment.getActiveProfiles();
        String profile = activeProfiles.length > 0 ? activeProfiles[0] : "default";

        // Prepare JWT claims
        String subject = "spring-demo-app-" + profile;
        Map<String, Object> claims = new HashMap<>();
        claims.put("profile", profile);

        try {
            // Generate JWT
            String jwt = JwtUtil.generateJwt(subject, claims, jwksFilePath);
            log.debug("Generated JWT: {}", jwt);

            // Retrieve secret from Conjur
            String secretPath = appConfig.getSecrets().get("my-secret");
            log.info("Retrieving secret from Conjur for path: {}", secretPath);
            String secret = conjurClient.retrieveSecret(secretPath);

            log.info("Successfully retrieved secret for profile: {}", profile);
            return "The secret is: " + secret;

        } catch (Exception e) {
            log.error("Error while retrieving secret: ", e);
            return "Error occurred while retrieving the secret.";
        }
    }
}
