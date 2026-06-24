package com.gewu.agent.dto;

public record ChatConfigResponse(
        boolean configured,
        String model,
        String baseUrl
) {
}
