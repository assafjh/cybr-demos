package com.cyberark.conjur.demo.controller;

import com.cyberark.conjur.demo.config.AppConfig;
import com.cyberark.conjur.demo.util.JwtUtil;
import com.cyberark.springboot.annotations.ConjurPropertySource;
import com.cyberark.springboot.annotations.ConjurValues;
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
@ConjurPropertySource({
    "${conjur.secrets.my-secret1}",
    "${conjur.secrets.my-secret2}",
    "${conjur.secrets.my-secret3}"
})
public class SecretController {

    private final AppConfig appConfig;
    private final Environment environment;

    @ConjurValues({
        @com.cyberark.springboot.annotations.ConjurValue(key = "${conjur.secrets.my-secret1}"),
        @com.cyberark.springboot.annotations.ConjurValue(key = "${conjur.secrets.my-secret2}"),
        @com.cyberark.springboot.annotations.ConjurValue(key = "${conjur.secrets.my-secret3}")
    })
    private Map<String, String> secrets;

    @GetMapping("/secrets")
    public Map<String, String> getSecrets() {
        log.info("Starting secrets retrieval process");

        // Check for 'init' mode
        String jwksFilePath = appConfig.getJwksFilePath();
        String initMode = System.getProperty("mode");
        if ("init".equalsIgnoreCase(initMode)) {
            try {
                JwtUtil.generateAndSaveJWKS(jwksFilePath);
                log.info("JWKS generated and saved at {}", jwksFilePath);
                return Map.of("message", "JWKS generated successfully!");
            } catch (Exception e) {
                log.error("Error generating JWKS: ", e);
                throw new RuntimeException("Error occurred while generating JWKS.", e);
            }
        }

        try {
            // Retrieve and log secrets
            secrets.forEach((key, value) -> log.info("Retrieved secret: {} = {}", key, value));
            return secrets;
        } catch (Exception e) {
            log.error("Error while retrieving secrets: ", e);
            throw new RuntimeException("Error occurred while retrieving the secrets.", e);
        }
    }
}
