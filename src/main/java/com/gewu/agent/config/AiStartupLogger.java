package com.gewu.agent.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiStartupLogger {

    private static final Logger log = LoggerFactory.getLogger(AiStartupLogger.class);

    @Bean
    ApplicationRunner deepSeekConfigLogger(DeepSeekProperties properties) {
        return args -> log.info("DeepSeek config: apiKey={}, model={}, baseUrl={}",
                properties.hasApiKey() ? "configured" : "not configured",
                properties.getChat().getModel(),
                properties.getBaseUrl());
    }
}
