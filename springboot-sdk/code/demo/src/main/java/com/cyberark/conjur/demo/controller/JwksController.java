package com.cyberark.conjur.demo.controller;

import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.JWKSet;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.KeyPair;

@RestController
@RequiredArgsConstructor
@Slf4j
public class JwksController {

    private final KeyPair keyPair;

    @GetMapping("/.well-known/jwks.json")
    public String getJwks() {
        log.info("Exposing JWKS endpoint");
        RSAKey rsaKey = new RSAKey.Builder((java.security.interfaces.RSAPublicKey) keyPair.getPublic())
                .keyID("key-id")
                .build();
        JWKSet jwkSet = new JWKSet(rsaKey);
        String jwks = jwkSet.toJSONObject().toJSONString();
        log.debug("Generated JWKS: {}", jwks);
        return jwks;
    }
}
