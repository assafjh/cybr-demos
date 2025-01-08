package com.cyberark.conjur.demo.util;

import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.JWKSet;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import lombok.extern.slf4j.Slf4j;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.security.Key;
import java.util.Date;
import java.util.Map;

@Slf4j
public class JwtUtil {

    // 10 years in milliseconds
    private static final long TEN_YEARS_MILLIS = 1000L * 60 * 60 * 24 * 365 * 10;

    // JWT expiration time (e.g., 10 minutes for individual tokens)
    private static final long EXPIRATION_TIME = 1000 * 60 * 10;

    /**
     * Generate and persist the JWKS file if it doesn't exist, or reuse the existing JWKS file.
     *
     * @param jwksFilePath Path to the JWKS file
     * @throws Exception If an error occurs during key generation or file handling
     */
    public static void generateAndSaveJWKS(String jwksFilePath) throws Exception {
        File jwksFile = new File(jwksFilePath);

        // If the JWKS file already exists, skip regeneration
        if (jwksFile.exists()) {
            log.info("JWKS file already exists at: {}", jwksFilePath);
            return;
        }

        log.info("Generating new JWKS file at: {}", jwksFilePath);

        // Generate a new RSA key pair
        RSAKey rsaKey = new RSAKey.Builder(RSAKey.generate(2048))
                .keyID("springboot-demo-key") // Optional: set a fixed key ID for reference
                .expirationTime(new Date(System.currentTimeMillis() + TEN_YEARS_MILLIS)) // Valid for 10 years
                .build();

        // Create the JWK Set and save it to the file
        JWKSet jwkSet = new JWKSet(rsaKey);
        try (FileWriter writer = new FileWriter(jwksFile)) {
            writer.write(jwkSet.toJSONObject().toString());
            log.info("Generated and saved JWKS at: {}", jwksFilePath);
        } catch (IOException e) {
            log.error("Error writing JWKS file to {}: {}", jwksFilePath, e.getMessage(), e);
            throw e;
        }
    }

    /**
     * Generate a JWT using the private key from the persisted JWKS file.
     *
     * @param subject      Subject (e.g., app name + profile)
     * @param customClaims Custom claims to add to the token
     * @param jwksFilePath Path to the JWKS file
     * @return Generated JWT
     */
    public static String generateJwt(String subject, Map<String, Object> customClaims, String jwksFilePath) {
        log.info("Generating JWT for subject: {}", subject);
        try {
            // Load the RSA key from the existing JWKS file
            RSAKey rsaKey = (RSAKey) JWKSet.load(new File(jwksFilePath)).getKeys().get(0);
            Key privateKey = rsaKey.toPrivateKey();

            // Build and sign the JWT
            String jwt = Jwts.builder()
                    .setSubject(subject) // Set the "sub" claim
                    .setIssuer("springboot-conjur-demo-app") // Set the "iss" claim
                    .setIssuedAt(new Date()) // Set the "iat" claim
                    .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME)) // Token expiration
                    .addClaims(customClaims) // Add custom claims
                    .signWith(privateKey, SignatureAlgorithm.RS256) // Sign with RSA private key
                    .compact();

            log.info("Successfully generated JWT for subject: {}", subject);
            log.debug("Generated JWT: {}", jwt);

            return jwt;

        } catch (IOException e) {
            log.error("Failed to load JWKS file at {}: {}", jwksFilePath, e.getMessage(), e);
            throw new RuntimeException("Failed to load JWKS file", e);
        }
    }
}
