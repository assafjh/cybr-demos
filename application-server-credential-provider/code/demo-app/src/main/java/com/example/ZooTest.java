package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class ZooTest {
    @Test
    void testAppEnvironment() {
        ZooServlet servlet = new ZooServlet();
        assertNotNull(servlet, "Servlet instance should be created successfully");
    }
}