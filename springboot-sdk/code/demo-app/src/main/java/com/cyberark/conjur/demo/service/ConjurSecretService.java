package com.cyberark.conjur.demo.service;

import com.cyberark.conjur.sdk.endpoint.SecretsApi;
import com.cyberark.conjur.sdk.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class ConjurSecretService {

    private static final Logger logger = LoggerFactory.getLogger(ConjurSecretService.class);
    private static final String KIND_VARIABLE = "variable";

    private final SecretsApi secretsApi;

    @Value("${conjur.account}")
    private String account;

    public ConjurSecretService(SecretsApi secretsApi) {
        this.secretsApi = secretsApi;
    }

    /**
     * Fetches a secret from Conjur using the Secrets API.
     *
     * @param identifier The URL-encoded variable ID of the secret.
     * @return The secret value as a String, or null if an error occurs.
     */
    public String getSecret(String identifier) {
        try {
            logger.info("Fetching secret for identifier: {}", identifier);
            return secretsApi.getSecret(account, KIND_VARIABLE, identifier);
        } catch (ApiException e) {
            handleApiException(identifier, e);
            return null; // Or rethrow a custom exception
        }
    }

    /**
     * Handles specific cases of ApiException and logs appropriately.
     *
     * @param identifier The secret identifier.
     * @param e          The ApiException instance.
     */
    private void handleApiException(String identifier, ApiException e) {
        String errorMessage = switch (e.getCode()) {
            case 400 -> "Malformed request syntax.";
            case 401 -> "Authentication failed. Ensure valid credentials.";
            case 403 -> "Access denied. Insufficient privileges.";
            case 404 -> "Secret not found or not set.";
            case 422 -> "Invalid or missing request parameters.";
            default -> "An unexpected error occurred.";
        };

        logger.error("Failed to fetch secret for identifier: {}. Error: {} (Code: {})",
                     identifier, errorMessage, e.getCode());
    }
}
