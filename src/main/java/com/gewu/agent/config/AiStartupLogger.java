package com.gewu.agent.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.model.deepseek.autoconfigure.DeepSeekChatProperties;
import org.springframework.ai.model.deepseek.autoconfigure.DeepSeekConnectionProperties;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

@Configuration
public class AiStartupLogger {

    private static final Logger log = LoggerFactory.getLogger(AiStartupLogger.class);

    @Bean
    ApplicationRunner deepSeekConfigLogger(
            DeepSeekConnectionProperties connectionProperties,
            DeepSeekChatProperties chatProperties
    ) {
        var options = chatProperties.toOptions();
        var apiKey = StringUtils.hasText(chatProperties.getApiKey())
                ? chatProperties.getApiKey()
                : connectionProperties.getApiKey();
        var baseUrl = StringUtils.hasText(chatProperties.getBaseUrl())
                ? chatProperties.getBaseUrl()
                : connectionProperties.getBaseUrl();

        return args -> log.info("DeepSeek config: apiKey={}, model={}, baseUrl={}",
                StringUtils.hasText(apiKey) ? "configured" : "not configured",
                options.getModel(),
                baseUrl);
    }
}
