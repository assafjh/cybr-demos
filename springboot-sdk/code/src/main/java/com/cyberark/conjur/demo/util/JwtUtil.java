package com.cyberark.conjur.demo.util;

import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.jwk.JWKSet;
import io.jsonwebtoken.Jwts;
import lombok.extern.slf4j.Slf4j;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
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

        // Generate RSA key pair
        KeyPair keyPair = generateRSAKeyPair();
        RSAKey rsaKey = new RSAKey.Builder((RSAPublicKey) keyPair.getPublic())
                .privateKey((RSAPrivateKey) keyPair.getPrivate())
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
            RSAPrivateKey privateKey = rsaKey.toRSAPrivateKey();

            // Build and sign the JWT
            String jwt = Jwts.builder()
                    .claim("sub", subject) // Set the "sub" claim (subject)
                    .claim("iss", "springboot-conjur-demo-app") // Set the "iss" claim (issuer)
                    .claim("iat", new Date()) // Set the "iat" claim (issued at)
                    .claim("exp", new Date(System.currentTimeMillis() + EXPIRATION_TIME)) // Set expiration time
                    .claims(customClaims) // Add custom claims
                    .signWith(privateKey) // Sign with RSA private key
                    .compact();

            log.info("Successfully generated JWT for subject: {}", subject);
            log.debug("Generated JWT: {}", jwt);

            return jwt;

        } catch (IOException e) {
            log.error("Failed to load JWKS file at {}: {}", jwksFilePath, e.getMessage(), e);
            throw new RuntimeException("Failed to load JWKS file", e);
        } catch (java.text.ParseException e) {
            log.error("Failed to parse the JWKS file at {}: {}", jwksFilePath, e.getMessage(), e);
            throw new RuntimeException("Failed to parse JWKS file", e);
        } catch (JOSEException e) {
            log.error("Failed to handle JOSE operation: {}", e.getMessage(), e);
            throw new RuntimeException("Error occurred while processing JOSE operation", e);
        }
    }

    /**
     * Generate an RSA key pair.
     *
     * @return RSA KeyPair containing public and private keys.
     * @throws Exception If an error occurs during key generation.
     */
    private static KeyPair generateRSAKeyPair() throws Exception {
        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
        keyPairGenerator.initialize(2048); // Set the key size
        return keyPairGenerator.generateKeyPair();
    }
}
