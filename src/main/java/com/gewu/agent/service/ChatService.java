package com.gewu.agent.service;

import com.gewu.agent.dto.ChatConfigResponse;
import com.gewu.agent.dto.ChatRequest;
import com.gewu.agent.dto.ChatResponse;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.deepseek.DeepSeekChatOptions;
import org.springframework.ai.model.deepseek.autoconfigure.DeepSeekChatProperties;
import org.springframework.ai.model.deepseek.autoconfigure.DeepSeekConnectionProperties;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;

@Service
public class ChatService {

    private final ChatClient chatClient;

    private final DeepSeekConnectionProperties connectionProperties;

    private final DeepSeekChatProperties chatProperties;

    public ChatService(
            ChatClient.Builder chatClientBuilder,
            DeepSeekConnectionProperties connectionProperties,
            DeepSeekChatProperties chatProperties
    ) {
        this.chatClient = chatClientBuilder.build();
        this.connectionProperties = connectionProperties;
        this.chatProperties = chatProperties;
    }

    public ChatConfigResponse config() {
        return new ChatConfigResponse(
                StringUtils.hasText(apiKey()),
                defaultModel(),
                baseUrl()
        );
    }

    public ChatResponse chat(ChatRequest request) {
        var model = modelFor(request);
        var content = chatClient.prompt()
                .user(request.message())
                .options(optionsFor(request))
                .call()
                .content();
        return new ChatResponse(content, model);
    }

    public Flux<String> stream(ChatRequest request) {
        return chatClient.prompt()
                .user(request.message())
                .options(optionsFor(request))
                .stream()
                .content();
    }

    private DeepSeekChatOptions.Builder optionsFor(ChatRequest request) {
        return DeepSeekChatOptions.builder()
                .model(modelFor(request))
                .temperature(temperatureFor(request));
    }

    private String modelFor(ChatRequest request) {
        if (request.model() != null && !request.model().isBlank()) {
            return request.model();
        }
        return defaultModel();
    }

    private String defaultModel() {
        var model = chatProperties.toOptions().getModel();
        return model == null || model.isBlank() ? "deepseek-v4-flash" : model;
    }

    private Double temperatureFor(ChatRequest request) {
        if (request.temperature() != null) {
            return request.temperature();
        }
        return chatProperties.toOptions().getTemperature();
    }

    private String apiKey() {
        return StringUtils.hasText(chatProperties.getApiKey())
                ? chatProperties.getApiKey()
                : connectionProperties.getApiKey();
    }

    private String baseUrl() {
        return StringUtils.hasText(chatProperties.getBaseUrl())
                ? chatProperties.getBaseUrl()
                : connectionProperties.getBaseUrl();
    }
}
