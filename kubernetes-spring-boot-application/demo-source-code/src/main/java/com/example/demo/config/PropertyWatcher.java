package com.example.demo.config;

import lombok.Cleanup;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.PropertiesPropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.scheduling.annotation.Scheduled;

import javax.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;
import java.util.Properties;
import java.util.stream.StreamSupport;

@Slf4j
public abstract class PropertyWatcher {

    @Autowired
    protected StandardEnvironment environment;
    private long lastModTime;
    private Path propertiesFilePath;
    private PropertySource<?> appConfigPropertySource;

    @PostConstruct
    private void init() {
        lastModTime = 0L;
        appConfigPropertySource = null;
        propertiesFilePath = locatePropertyFilePath(getPropertyFileName());
    }

    private Path locatePropertyFilePath(String filename) {
        MutablePropertySources propertySources = environment.getPropertySources();
        Optional<PropertySource<?>> appConfigPsOp =
                StreamSupport.stream(propertySources.spliterator(), false)
                        .filter(ps -> ps.getName().matches("^.*file.*"+filename+".*$"))
                        .findFirst();
        if (appConfigPsOp.isEmpty())  {
            throw new RuntimeException("Unable to find property Source as file");
        }
        appConfigPropertySource = appConfigPsOp.get();

        String locatedFileName = appConfigPropertySource.getName();
        locatedFileName = locatedFileName
                .replace("URL [file:", "")
                .replaceAll("]$", "");
        return Paths.get(locatedFileName);
    }

    @Scheduled(fixedRate=2000)
    private void reloadPropertyFile() {
        try {
            long currentModTs = Files.getLastModifiedTime(propertiesFilePath).toMillis();
            if (currentModTs > lastModTime) {
                lastModTime = currentModTs;
                Properties properties = new Properties();
                @Cleanup InputStream inputStream = Files.newInputStream(propertiesFilePath);
                properties.load(inputStream);
                environment.getPropertySources()
                        .replace(
                                appConfigPropertySource.getName(),
                                new PropertiesPropertySource(
                                        appConfigPropertySource.getName(),
                                        properties
                                )
                        );
                log.info("Detected changes in {}", propertiesFilePath);
                actionsAfterReload();
            }
        } catch (IOException e) {
            log.error("Error watching properties file: {}", e.getMessage(), e);
        }
    }

    protected abstract String getPropertyFileName();

    protected abstract void actionsAfterReload();

}

