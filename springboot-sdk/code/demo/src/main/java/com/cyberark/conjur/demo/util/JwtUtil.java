package com.cyberark.conjur.demo.util;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.util.Base64URL;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.Date;
import java.util.Map;

public class JwtUtil {

    private static final long EXPIRATION_TIME = 1000 * 60 * 60 * 24 * 365 * 10; // 10 years in milliseconds

    // Generate and save the JWKS file if it doesn't exist
    public static void generateAndSaveJWKS(String jwksFilePath) throws Exception {
        File jwksFile = new File(jwksFilePath);
        if (jwksFile.exists()) {
            System.out.println("JWKS file already exists. Using existing JWKS.");
            return;
        }

        System.out.println("Generating new JWKS and saving to file...");

        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
        keyPairGenerator.initialize(2048);
        KeyPair keyPair = keyPairGenerator.generateKeyPair();

        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
        RSAKey rsaKey = new RSAKey.Builder(publicKey)
                .privateKey((PrivateKey) keyPair.getPrivate())
                .keyID(Base64URL.encode("key1"))
                .build();

        JWKSet jwkSet = new JWKSet(rsaKey);

        try (FileWriter fileWriter = new FileWriter(jwksFile)) {
            fileWriter.write(jwkSet.toString());
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException("Error saving JWKS to file", e);
        }

        System.out.println("JWKS saved to file: " + jwksFilePath);
    }

    // Load JWKS from the given file path
    public static JWKSet loadJWKS(String jwksFilePath) throws Exception {
        File jwksFile = new File(jwksFilePath);
        if (!jwksFile.exists()) {
            generateAndSaveJWKS(jwksFilePath);
        }

        return JWKSet.load(jwksFile);
    }

    // Generate JWT using JWKS for signing
    public static String generateJwt(String subject, Map<String, Object> customClaims, String jwksFilePath) throws Exception {
        JWKSet jwkSet = loadJWKS(jwksFilePath);

        JWK jwk = jwkSet.getKeys().get(0);

        PrivateKey privateKey = (PrivateKey) jwk.getPrivateKey();

        var jwtBuilder = Jwts.builder()
                .setSubject(subject)
                .setIssuer("springboot-conjur-demo-app")
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(privateKey, SignatureAlgorithm.RS256);

        if (customClaims != null) {
            jwtBuilder.addClaims(customClaims);
        }

        return jwtBuilder.compact();
    }
}
