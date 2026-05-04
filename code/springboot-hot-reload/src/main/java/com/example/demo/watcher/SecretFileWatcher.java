package com.example.demo.watcher;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.refresh.ContextRefresher;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.io.IOException;
import java.nio.file.*;

@Component
public class SecretFileWatcher {

    private static final Logger log = LoggerFactory.getLogger(SecretFileWatcher.class);
    private static final long DEBOUNCE_MS = 1_000;

    private final ContextRefresher contextRefresher;
    private final String watchDir;
    private Thread watcherThread;
    private volatile long lastRefreshAt = 0;

    public SecretFileWatcher(ContextRefresher contextRefresher,
                             @Value("${secrets.watch-dir:/etc/conjur/secrets}") String watchDir) {
        this.contextRefresher = contextRefresher;
        this.watchDir = watchDir;
    }

    @PostConstruct
    public void startWatching() {
        Path path = Paths.get(watchDir);
        if (!Files.exists(path)) {
            log.warn("Secrets directory '{}' does not exist — file watcher disabled. " +
                     "Create the directory or set secrets.watch-dir to enable hot-reload.", watchDir);
            return;
        }

        watcherThread = new Thread(() -> {
            try (WatchService watchService = FileSystems.getDefault().newWatchService()) {
                path.register(watchService,
                        StandardWatchEventKinds.ENTRY_CREATE,
                        StandardWatchEventKinds.ENTRY_MODIFY);
                log.info("Watching '{}' for credential changes", watchDir);

                while (!Thread.currentThread().isInterrupted()) {
                    WatchKey key = watchService.take();
                    for (WatchEvent<?> event : key.pollEvents()) {
                        long now = System.currentTimeMillis();
                        if (now - lastRefreshAt > DEBOUNCE_MS) {
                            lastRefreshAt = now;
                            log.info("Credentials file changed ({}), refreshing context", event.context());
                            contextRefresher.refresh();
                            log.info("Context refreshed — new credentials active");
                        }
                    }
                    key.reset();
                }
            } catch (IOException e) {
                log.error("File watcher failed to start: {}", e.getMessage());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "secret-file-watcher");
        watcherThread.setDaemon(true);
        watcherThread.start();
    }

    @PreDestroy
    public void stopWatching() {
        if (watcherThread != null) {
            watcherThread.interrupt();
        }
    }
}
