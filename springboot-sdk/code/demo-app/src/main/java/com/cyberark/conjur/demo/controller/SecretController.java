package com.cyberark.conjur.demo.controller;

import com.cyberark.conjur.demo.config.DynamicSecretConfiguration;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.HashMap;
import java.util.Map;

@Controller
public class SecretController {

    private final DynamicSecretConfiguration dynamicSecretConfiguration;

    public SecretController(DynamicSecretConfiguration dynamicSecretConfiguration) {
        this.dynamicSecretConfiguration = dynamicSecretConfiguration;
    }

    @GetMapping("/secret")
    public String getSecret(Model model) {
        // Build a map of secrets (key -> value)
        Map<String, String> secrets = new HashMap<>();
        secrets.put(dynamicSecretConfiguration.getSecretOne(), dynamicSecretConfiguration.getSecretOneValue());
        secrets.put(dynamicSecretConfiguration.getSecretTwo(), dynamicSecretConfiguration.getSecretTwoValue());
        secrets.put(dynamicSecretConfiguration.getSecretThree(), dynamicSecretConfiguration.getSecretThreeValue());

        // Pass the secrets map to the Thymeleaf model
        model.addAttribute("secrets", secrets);

        // Return the name of the Thymeleaf template (secret.html)
        return "secret";
    }
}
