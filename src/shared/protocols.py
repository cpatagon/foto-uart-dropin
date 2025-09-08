"""Protocolos de comunicación compartidos entre componentes."""

class UARTProtocol:
    """Protocolo UART estándar para comunicación Pi-ESP32."""
    
    # Comandos
    CMD_FOTO = "FOTO"
    CMD_STATUS = "STATUS"
    CMD_CONFIG = "CONFIG"
    
    # Respuestas
    RESP_READY = "READY"
    RESP_ACK = "ACK"
    RESP_DONE = "DONE"
    RESP_ERROR = "ERROR"
    
    # Timeouts
    TIMEOUT_ACK = 10
    TIMEOUT_RESPONSE = 30
