package com.cyberark.conjur.demo.controller;

import com.cyberark.conjur.demo.config.AppConfig;
import com.cyberark.conjur.demo.util.JwtUtil;
import com.cyberark.springboot.conjur.ConjurSecret;
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
    private final Environment environment; // Access to active profiles

    @GetMapping("/secret")
    public String getSecret() {
        log.info("Generating JWT for Conjur authentication");

        // Get JWKS file path from AppConfig
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

        // Regular mode for generating JWT and fetching secret
        String[] activeProfiles = environment.getActiveProfiles();
        String profile = activeProfiles.length > 0 ? activeProfiles[0] : "default";

        String subject = "spring-demo-app-" + profile;

        Map<String, Object> claims = new HashMap<>();
        claims.put("profile", profile);

        try {
            // Generate JWT using JWKS (it will use the JWKS file if it exists, otherwise it will generate and save it)
            String jwt = JwtUtil.generateJwt(subject, claims, jwksFilePath);
            log.debug("Generated JWT: {}", jwt);

            log.info("Fetching secret from Conjur");
            String secret = ConjurSecret.retrieve(appConfig.getSecretPath(), jwt);
            log.debug("Retrieved secret: {}", secret);

            return "The secret is: " + secret;

        } catch (Exception e) {
            log.error("Error while generating JWT or fetching secret: ", e);
            return "Error occurred";
        }
    }
}
