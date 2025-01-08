package com.cyberark.conjur.demo.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
@Getter
public class AppConfig {

    @Value("${conjur.secrets.my-secret}")
    private String secretPath;

    @Value("${conjur.account}")
    private String conjurAccount;

    @Value("${conjur.appliance-url}")
    private String applianceUrl;

    @Value("${conjur.authn-jwt.service-id}")
    private String serviceId;

    @Value("${jwks.file-path:./jwks.json}") // Default to './jwks.json' if not provided
    private String jwksFilePath;

}