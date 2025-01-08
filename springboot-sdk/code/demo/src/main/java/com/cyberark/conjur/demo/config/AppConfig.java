package com.cyberark.conjur.demo.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

@Configuration
@ConfigurationProperties(prefix = "conjur")
@Data
public class AppConfig {
    private String account;
    private String applianceUrl;
    private AuthnJwt authnJwt;
    private Map<String, String> secrets;
<<<<<<< HEAD
    private String jwksFilePath; // Path to JWKS file
=======
>>>>>>> d98950cfea16f019d4c8dfb991cf693ba52ac46c

    @Data
    public static class AuthnJwt {
        private String serviceId;
    }
<<<<<<< HEAD
=======

    // JWKS file path property
    private String jwksFilePath;
>>>>>>> d98950cfea16f019d4c8dfb991cf693ba52ac46c
}
