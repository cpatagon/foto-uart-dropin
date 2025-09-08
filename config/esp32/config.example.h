// Configuración ESP32 - Renombrar a config.h
#ifndef CONFIG_H
#define CONFIG_H

// UART Configuration
#define UART_BAUDRATE 115200
#define UART_RX_PIN 16
#define UART_TX_PIN 17

// SIM7600 Configuration  
#define SIM7600_PWR_PIN 4
#define SIM7600_RST_PIN 5

// Camera Configuration
#define CAMERA_MODEL AI_THINKER
#define CAMERA_PIN_PWDN 32
#define CAMERA_PIN_RESET -1

// WiFi Configuration (opcional)
#define WIFI_SSID "your_wifi_ssid"
#define WIFI_PASSWORD "your_wifi_password"

// Server Configuration
#define SERVER_URL "http://your-server.com/api/images"
#define API_KEY "your_api_key"

#endif
