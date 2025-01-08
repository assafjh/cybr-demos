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

    @Data
    public static class AuthnJwt {
        private String serviceId;
    }

    // JWKS file path property
    private String jwksFilePath;
}
