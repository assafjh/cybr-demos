# Spring Boot Conjur JWT Integration

This is a Spring Boot application that demonstrates integration with CyberArk Conjur for secure secret management. The application dynamically generates JWTs, exposes a JWKS endpoint for Conjur authentication, and retrieves secrets from Conjur.

---

## Features

- **JWT Generation**: Dynamically generates JWTs with customizable claims (`sub`).
- **JWKS Endpoint**: Exposes a JWKS endpoint (`/.well-known/jwks.json`) for Conjur to validate JWTs.
- **Secret Retrieval**: Authenticates with Conjur using JWT and retrieves secrets securely.
- **Profile-Specific Configuration**: Supports multiple environments (`dev`, `prod`) via Spring Boot profiles.
- **Logging**: Detailed logs for JWT generation, JWKS exposure, and secret retrieval.

---

## Requirements

- **Java**: JDK 17 or higher
- **Conjur**: CyberArk Conjur server
- **Gradle**: 7.x or higher
- **Spring Boot**: 3.1.x

---

## Configuration

### 1. Profiles
This application supports different profiles (`dev`, `prod`) using `application.yml` and profile-specific configuration files (`application-dev.yml`, `application-prod.yml`).

### 2. Application Configuration

#### `application.yml`
```yaml
spring:
  application:
    name: conjur-demo
  profiles:
    active: dev
```

#### `application-dev.yml`
```yaml
conjur:
  account: dev-conjur-account
  appliance-url: https://conjur.dev.my-org.com
  authn-jwt:
    service-id: dev-jwt-service
  secrets:
    my-secret: dev/my-app/database/password
```

#### `application-prod.yml`
```yaml
conjur:
  account: prod-conjur-account
  appliance-url: https://conjur.prod.my-org.com
  authn-jwt:
    service-id: prod-jwt-service
  secrets:
    my-secret: prod/my-app/database/password
```

### 3. Port Configuration
Set the server port using one of the following methods:
- In `application.yml`:
  ```yaml
  server:
    port: 9090
  ```
- Via command-line argument:
  ```bash
  java -jar demo-app.jar --server.port=9090
  ```

---

## Endpoints

### 1. JWKS Endpoint
- **Path**: `/.well-known/jwks.json`
- **Description**: Exposes the public key for JWT validation by Conjur.

### 2. Secret Retrieval Endpoint
- **Path**: `/secret`
- **Description**: Authenticates with Conjur using JWT and retrieves a secret.

---

## Run the Application

### 1. Clone the Repository
```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Build the Application
```bash
./gradlew build
```

### 3. Run the Application
```bash
./gradlew bootRun
```

### 4. Access Endpoints
- JWKS: [http://localhost:9090/.well-known/jwks.json](http://localhost:8080/.well-known/jwks.json)
- Secret: [http://localhost:9090/secret](http://localhost:8080/secret)

---

## Logging

This application uses SLF4J with Spring Boot’s default logging setup. Logs include:
- JWT generation details.
- JWKS exposure logs.
- Secret retrieval details.

To customize logging, update `application.yml`:
```yaml
logging:
  level:
    root: INFO
    com.cyberark.conjur.demo: DEBUG
```

---

## Security Notes

- Ensure the RSA private key is stored securely.
- Use environment variables or externalized configuration for sensitive data, such as Conjur credentials.
- Regularly rotate keys and tokens.

---

## Dependencies

- Spring Boot 3.4.x
- CyberArk Conjur Spring Boot SDK
- JJWT (Java JWT library)
- Lombok
- SLF4J

---

## Conjur - How to load policies
```bash
conjur policy update -b data -f ./policies/01-base.yml | tee -a 01-base.log
conjur policy update -b data/springboot -f ./policies/02-define-springboot-branch.yml | tee -a 02-define-springboot-branch.log
conjur policy update -b data -f ./policies/03-add-permissions.yml | tee -a 03-add-permissions.log
conjur policy update -b conjur/authn-jwt -f ./policies/04-define-jwt-auth.yml | tee -a 04-define-jwt-auth.log
```

---

## License

This project is licensed under the [MIT License](LICENSE).
