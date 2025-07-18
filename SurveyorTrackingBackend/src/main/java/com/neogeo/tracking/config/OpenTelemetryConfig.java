package com.neogeo.tracking.config;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.sdk.trace.export.SpanExporter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenTelemetryConfig {

    @Value("${spring.application.name:surveyor-tracking-backend}")
    private String applicationName;

    @Value("${opentelemetry.otlp.endpoint:}")
    private String otlpEndpoint;

    @Value("${opentelemetry.traces.exporter:none}")
    private String tracesExporter;

    @Bean
    public OpenTelemetry openTelemetry() {
        // If tracing is disabled or no endpoint configured, return a no-op implementation
        if ("none".equals(tracesExporter) || otlpEndpoint == null || otlpEndpoint.trim().isEmpty()) {
            return OpenTelemetry.noop();
        }

        // Create resource with service name
        Resource resource = Resource.getDefault()
                .merge(Resource.create(Attributes.of(
                        AttributeKey.stringKey("service.name"), applicationName
                )));

        // Create tracer provider
        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
                .addSpanProcessor(BatchSpanProcessor.builder(createSpanExporter()).build())
                .setResource(resource)
                .build();

        // Create and return OpenTelemetry SDK
        return OpenTelemetrySdk.builder()
                .setTracerProvider(tracerProvider)
                .buildAndRegisterGlobal();
    }

    private SpanExporter createSpanExporter() {
        // For now, return a no-op exporter since we're not using tracing
        return new SpanExporter() {
            @Override
            public io.opentelemetry.sdk.common.CompletableResultCode export(
                    java.util.Collection<io.opentelemetry.sdk.trace.data.SpanData> spans) {
                return io.opentelemetry.sdk.common.CompletableResultCode.ofSuccess();
            }

            @Override
            public io.opentelemetry.sdk.common.CompletableResultCode flush() {
                return io.opentelemetry.sdk.common.CompletableResultCode.ofSuccess();
            }

            @Override
            public io.opentelemetry.sdk.common.CompletableResultCode shutdown() {
                return io.opentelemetry.sdk.common.CompletableResultCode.ofSuccess();
            }
        };
    }

    @Bean
    public Tracer tracer(OpenTelemetry openTelemetry) {
        return openTelemetry.getTracer(applicationName);
    }
}
