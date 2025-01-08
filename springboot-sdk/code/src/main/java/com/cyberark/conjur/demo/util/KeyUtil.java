package com.cyberark.conjur.demo.util;

import lombok.extern.slf4j.Slf4j;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;

@Slf4j
public class KeyUtil {

    public static KeyPair generateRsaKeyPair() {
        try {
            log.info("Generating RSA key pair");
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            return keyPairGenerator.generateKeyPair();
        } catch (NoSuchAlgorithmException e) {
            log.error("Failed to generate RSA key pair", e);
            throw new RuntimeException("Failed to generate RSA key pair", e);
        }
    }
}
