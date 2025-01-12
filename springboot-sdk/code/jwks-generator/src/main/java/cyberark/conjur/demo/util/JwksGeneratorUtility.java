package com.cyberark.conjur.demo.util;

import java.io.*;
import java.security.*;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

public class JwksGeneratorUtility {

    private static final String PRIVATE_KEY_PATH = "private.pem";
    private static final String PUBLIC_KEY_PATH = "public.pem";
    private static final String JWKS_FILE_PATH = "jwks.json";

    /**
     * Generates RSA key pair (private/public) if they don't exist, and returns the public key.
     */
    public RSAPublicKey generateKeyPair() throws Exception {
        KeyPair keyPair = generateKeyPairIfNeeded();
        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
        saveKeyPairToFiles(keyPair);
        return publicKey;
    }

    /**
     * Generates a new RSA key pair if the private/public keys do not exist, else loads the existing keys.
     */
    private KeyPair generateKeyPairIfNeeded() throws Exception {
        File privateKeyFile = new File(PRIVATE_KEY_PATH);
        File publicKeyFile = new File(PUBLIC_KEY_PATH);

        if (!privateKeyFile.exists() || !publicKeyFile.exists()) {
            // Generate new RSA key pair if the files don't exist
            return generateNewKeyPair();
        } else {
            // Load existing keys from files
            return loadExistingKeyPair();
        }
    }

    /**
     * Generates a new RSA key pair (private + public).
     */
    private KeyPair generateNewKeyPair() throws NoSuchAlgorithmException {
        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
        keyPairGenerator.initialize(2048);  // Key size of 2048 bits
        return keyPairGenerator.generateKeyPair();
    }

    /**
     * Loads an existing RSA key pair (private + public) from files.
     */
    private KeyPair loadExistingKeyPair() throws Exception {
        // Load the private key from file
        PrivateKey privateKey = readPrivateKeyFromFile();
        // Load the public key from file
        PublicKey publicKey = readPublicKeyFromFile();
        return new KeyPair(publicKey, privateKey);
    }

    /**
     * Read the private key from the file.
     */
    private PrivateKey readPrivateKeyFromFile() throws Exception {
        FileInputStream fis = new FileInputStream(PRIVATE_KEY_PATH);
        byte[] encodedKey = fis.readAllBytes();
        fis.close();
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePrivate(new PKCS8EncodedKeySpec(encodedKey));
    }

    /**
     * Read the public key from the file.
     */
    private PublicKey readPublicKeyFromFile() throws Exception {
        FileInputStream fis = new FileInputStream(PUBLIC_KEY_PATH);
        byte[] encodedKey = fis.readAllBytes();
        fis.close();
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePublic(new X509EncodedKeySpec(encodedKey));
    }

    /**
     * Save the private and public keys to files.
     */
    private void saveKeyPairToFiles(KeyPair keyPair) throws IOException {
        // Save private key to file
        try (FileOutputStream fos = new FileOutputStream(PRIVATE_KEY_PATH)) {
            fos.write(keyPair.getPrivate().getEncoded());
        }
        // Save public key to file
        try (FileOutputStream fos = new FileOutputStream(PUBLIC_KEY_PATH)) {
            fos.write(keyPair.getPublic().getEncoded());
        }
    }

    /**
     * Generate the JWKS (JSON Web Key Set) from the public key.
     * The `kid` (Key ID) is auto-generated based on the current timestamp.
     */
    public String generateJwks(RSAPublicKey publicKey) {
        // Auto-generate `kid` using the current timestamp (in milliseconds)
        String kid = "conjur-springboot-demo-" + System.currentTimeMillis();

        // Extract modulus (n) and exponent (e) from the public key
        String modulus = Base64.getUrlEncoder().encodeToString(publicKey.getModulus().toByteArray());
        String exponent = Base64.getUrlEncoder().encodeToString(publicKey.getPublicExponent().toByteArray());

        // Build the JWKS in JSON format with the dynamically generated kid
        return String.format("{\n" +
                "  \"keys\": [\n" +
                "    {\n" +
                "      \"kty\": \"RSA\",\n" +
                "      \"kid\": \"%s\",\n" +
                "      \"use\": \"sig\",\n" +
                "      \"alg\": \"RS256\",\n" +
                "      \"n\": \"%s\",\n" +
                "      \"e\": \"%s\"\n" +
                "    }\n" +
                "  ]\n" +
                "}", kid, modulus, exponent);
    }

    /**
     * Save JWKS to file for easy access.
     */
    public void saveJwksToFile(String jwksJson) throws IOException {
        try (FileWriter file = new FileWriter(JWKS_FILE_PATH)) {
            file.write(jwksJson);
        }
    }

    public static void main(String[] args) throws Exception {
        // Create a new instance of JwksGeneratorUtility
        JwksGeneratorUtility jwksUtil = new JwksGeneratorUtility();

        // Generate RSA key pair
        RSAPublicKey publicKey = jwksUtil.generateKeyPair();

        // Generate the JWKS
        String jwks = jwksUtil.generateJwks(publicKey);

        // Save the JWKS to a file
        jwksUtil.saveJwksToFile(jwks);

        // Optionally print the JWKS to the console
        System.out.println(jwks);
    }
}
