package com.gewu.agent.service;

import com.gewu.agent.config.DeepSeekProperties;
import com.gewu.agent.dto.ChatConfigResponse;
import com.gewu.agent.dto.ChatRequest;
import com.gewu.agent.dto.ChatResponse;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.deepseek.DeepSeekChatModel;
import org.springframework.ai.deepseek.DeepSeekChatOptions;
import org.springframework.ai.deepseek.api.DeepSeekApi;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Service
public class ChatService {

    private final DeepSeekProperties properties;

    public ChatService(DeepSeekProperties properties) {
        this.properties = properties;
    }

    public ChatConfigResponse config() {
        return new ChatConfigResponse(properties.hasApiKey(), defaultModel(), properties.getBaseUrl());
    }

    public ChatResponse chat(ChatRequest request) {
        var model = modelFor(request);
        var response = chatModel(request).call(new Prompt(new UserMessage(request.message())));
        return new ChatResponse(response.getResult().getOutput().getText(), model);
    }

    public Flux<String> stream(ChatRequest request) {
        var prompt = new Prompt(new UserMessage(request.message()));
        return chatModel(request).stream(prompt)
                .<String>handle((response, sink) -> {
                    if (response.getResult() == null || response.getResult().getOutput() == null) {
                        return;
                    }
                    var text = response.getResult().getOutput().getText();
                    if (text != null && !text.isEmpty()) {
                        sink.next(text);
                    }
                });
    }

    private DeepSeekChatModel chatModel(ChatRequest request) {
        if (!properties.hasApiKey()) {
            throw new IllegalStateException("DeepSeek API key is not configured. Set DEEPSEEK_API_KEY before starting the backend.");
        }

        var api = DeepSeekApi.builder()
                .apiKey(properties.getApiKey())
                .baseUrl(properties.getBaseUrl())
                .build();

        var options = DeepSeekChatOptions.builder()
                .model(modelFor(request))
                .temperature(temperatureFor(request))
                .build();

        return DeepSeekChatModel.builder()
                .deepSeekApi(api)
                .options(options)
                .build();
    }

    private String modelFor(ChatRequest request) {
        if (request.model() != null && !request.model().isBlank()) {
            return request.model();
        }
        return defaultModel();
    }

    private String defaultModel() {
        var model = properties.getChat().getModel();
        return model == null || model.isBlank() ? "deepseek-v4-flash" : model;
    }

    private Double temperatureFor(ChatRequest request) {
        if (request.temperature() != null) {
            return request.temperature();
        }
        return properties.getChat().getTemperature();
    }
}
