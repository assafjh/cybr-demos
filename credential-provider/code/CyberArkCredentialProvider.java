import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;
import java.util.Arrays;
import javapasswordsdk.*;
import javapasswordsdk.exceptions.*;

public class CyberArkCredentialProvider {

    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Please provide the path to the config.properties file.");
            return;
        }

        String propertiesFilePath = args[0];
        Properties properties = new Properties();

        // Load properties from config file
        try (FileInputStream input = new FileInputStream(propertiesFilePath)) {
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

        PSDKPassword password = null;
        char[] content = null;

        try {
            PSDKPasswordRequest passRequest = new PSDKPasswordRequest();

            // Set request properties
            passRequest.setAppID(appId);
            passRequest.setQuery("Safe=" + safe + ";Folder=" + folder + ";Object=" + objectName);
            passRequest.setReason(reason);

            // Get password object
            password = PasswordSDK.getPassword(passRequest);

            // Get password content
            content = password.getSecureContent();

            // Print the password (for demonstration purposes; be careful with printing sensitive information)
            System.out.println("Retrieved password: " + new String(content));

        } catch (PSDKException ex) {
            System.err.println("Error retrieving password: " + ex.getMessage());
            ex.printStackTrace();
        } finally {
            if (content != null) {
                // Clean the returned object
                Arrays.fill(content, (char) 0);
            }
            if (password != null) {
                // Dispose of resources used by this PSDKPassword object
                try {
                    password.dispose();
                } catch (PSDKException e) {
                    System.err.println("Error disposing password object: " + e.getMessage());
                }
            }
        }
    }
}

