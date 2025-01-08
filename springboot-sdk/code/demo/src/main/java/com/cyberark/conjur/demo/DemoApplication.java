package com.cyberark.conjur.demo;

import com.cyberark.conjur.demo.util.KeyUtil;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.security.KeyPair;

@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @Bean
    public KeyPair keyPair() {
        return KeyUtil.generateRsaKeyPair();
    }
}
