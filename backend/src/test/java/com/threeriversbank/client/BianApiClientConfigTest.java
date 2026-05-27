package com.threeriversbank.client;

import feign.Logger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@TestPropertySource(properties = {
    "bian.api.base-url=https://virtserver.swaggerhub.com/B154/BIAN/CreditCard/13.0.0",
    "feign.client.config.bian-api.connectTimeout=5000",
    "feign.client.config.bian-api.readTimeout=5000"
})
class BianApiClientConfigTest {

    private BianApiClientConfig config;

    @BeforeEach
    void setUp() {
        config = new BianApiClientConfig();
    }

    @Test
    @DisplayName("Should create Feign logger bean with FULL level")
    void feignLoggerLevel_ShouldReturnFullLevel() {
        // Act
        Logger.Level logLevel = config.feignLoggerLevel();

        // Assert
        assertThat(logLevel).isNotNull();
        assertThat(logLevel).isEqualTo(Logger.Level.FULL);
    }

    @Test
    @DisplayName("Should configure Feign client with correct logging level")
    void configuration_ShouldProvideFullLogging() {
        // Arrange
        Logger.Level level = config.feignLoggerLevel();

        // Assert
        assertThat(level).isEqualTo(Logger.Level.FULL);
    }
}
