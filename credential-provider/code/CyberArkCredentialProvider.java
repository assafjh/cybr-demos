import com.cyberark.passwordsdk.PasswordSDK;
import com.cyberark.passwordsdk.exceptions.PasswordSDKException;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class CyberArkCredentialProvider {

    public static void main(String[] args) {
        Properties properties = new Properties();

        // Load properties from config file
        try (FileInputStream input = new FileInputStream("config.properties")) {
            properties.load(input);
        } catch (IOException e) {
            System.err.println("Error loading properties file: " + e.getMessage());
            e.printStackTrace();
            return;
        }

        String appId = properties.getProperty("appId");
        String safe = properties.getProperty("safe");
        String folder = properties.getProperty("folder");
        String objectName = properties.getProperty("objectName");
        String reason = properties.getProperty("reason");
        String connectionTimeout = properties.getProperty("connectionTimeout");

        try {
            // Initialize the PasswordSDK
            PasswordSDK.init();

            // Retrieve the password
            String password = PasswordSDK.getPassword(appId, safe, folder, objectName, reason, connectionTimeout);

            // Print the password
            System.out.println("Retrieved password: " + password);

            // Terminate the PasswordSDK
            PasswordSDK.terminate();
        } catch (PasswordSDKException e) {
            System.err.println("Error retrieving password: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
