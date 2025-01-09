package com.cyberark.conjur.demo.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.cyberark.conjur.demo.config.DynamicSecretConfiguration;

@RestController
public class SecretController {

    private final DynamicSecretConfiguration dynamicSecretConfiguration;

    public SecretController(DynamicSecretConfiguration dynamicSecretConfiguration) {
        this.dynamicSecretConfiguration = dynamicSecretConfiguration;
    }

    @GetMapping(value = "/secret", produces = MediaType.TEXT_HTML_VALUE)
    public String getSecret() {
        return String.format(
            "Retrieved <b>%s</b>: %s<br>" +
            "Retrieved <b>%s</b>: %s<br>" +
            "Retrieved <b>%s</b>: %s",
            dynamicSecretConfiguration.getSecretOne(),
            dynamicSecretConfiguration.getSecretOneValue(),
            dynamicSecretConfiguration.getSecretTwo(),
            dynamicSecretConfiguration.getSecretTwoValue(),
            dynamicSecretConfiguration.getSecretThree(),
            dynamicSecretConfiguration.getSecretThreeValue()
        );
    }
    
}
