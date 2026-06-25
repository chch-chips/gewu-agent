package com.gewu.agent.service;

import com.gewu.agent.dto.ChatRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.deepseek.DeepSeekChatOptions;
import org.springframework.ai.model.deepseek.autoconfigure.DeepSeekChatProperties;
import org.springframework.ai.model.deepseek.autoconfigure.DeepSeekConnectionProperties;
import reactor.core.publisher.Flux;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ChatServiceTest {

    private ChatClient chatClient;

    private ChatClient.ChatClientRequestSpec requestSpec;

    private ChatService chatService;

    @BeforeEach
    void setUp() {
        var builder = mock(ChatClient.Builder.class);
        chatClient = mock(ChatClient.class);
        requestSpec = mock(ChatClient.ChatClientRequestSpec.class);

        when(builder.build()).thenReturn(chatClient);
        when(chatClient.prompt()).thenReturn(requestSpec);
        when(requestSpec.user(any(String.class))).thenReturn(requestSpec);
        when(requestSpec.options(any())).thenReturn(requestSpec);

        var connectionProperties = mock(DeepSeekConnectionProperties.class);
        var chatProperties = mock(DeepSeekChatProperties.class);
        when(chatProperties.toOptions()).thenReturn(
                DeepSeekChatOptions.builder()
                        .model("deepseek-v4-flash")
                        .temperature(0.7)
                        .build()
        );

        chatService = new ChatService(builder, connectionProperties, chatProperties);
    }

    @Test
    void delegatesSynchronousChatToChatClient() {
        var callResponse = mock(ChatClient.CallResponseSpec.class);
        when(requestSpec.call()).thenReturn(callResponse);
        when(callResponse.content()).thenReturn("完整回答");

        var response = chatService.chat(new ChatRequest("问题", "deepseek-v4-pro", 0.2));

        assertEquals("完整回答", response.content());
        assertEquals("deepseek-v4-pro", response.model());
        verify(requestSpec).user("问题");
        verify(requestSpec).options(any());
    }

    @Test
    void delegatesStreamingChatToChatClientContentFlux() {
        var streamResponse = mock(ChatClient.StreamResponseSpec.class);
        when(requestSpec.stream()).thenReturn(streamResponse);
        when(streamResponse.content()).thenReturn(Flux.just("Spring", " AI", " 2.0"));

        var content = chatService.stream(new ChatRequest("问题", "deepseek-v4-flash", 0.1))
                .collectList()
                .block();

        assertEquals("Spring AI 2.0", String.join("", content));
        verify(requestSpec).user("问题");
        verify(requestSpec).options(any());
    }
}
