package com.cyberark.conjur.demo.config;

import com.cyberark.conjur.demo.service.ConjurSecretService;

import lombok.Getter;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DynamicSecretConfiguration {

    private final ConjurSecretService conjurSecretService;

    public DynamicSecretConfiguration(ConjurSecretService conjurSecretService) {
        this.conjurSecretService = conjurSecretService;
    }

    @Getter
    @Value("${conjur.secret.one}")
    private String secretOne;

    @Getter
    @Value("${conjur.secret.two}")
    private String secretTwo;

    @Getter
    @Value("${conjur.secret.three}")
    private String secretThree;

    public String getSecretOneValue() {
        return conjurSecretService.getSecret(secretOne);
    }

    public String getSecretTwoValue() {
        return conjurSecretService.getSecret(secretTwo);
    }

    public String getSecretThreeValue() {
        return conjurSecretService.getSecret(secretThree);
    }

}
