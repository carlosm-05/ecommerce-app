package com.uniminuto.ecommerce.dto;

import java.time.Instant;
import java.util.Map;

public final class CommonDtos {

    private CommonDtos() {}

    public record MessageResponse(String message) {}

    /**
     * Formato unico de error. En Flutter: muestra {@code fieldErrors[campo]} debajo de cada
     * TextFormField (errores inline) y {@code message} en un SnackBar.
     */
    public record ErrorResponse(
            int status,
            String error,
            String message,
            Map<String, String> fieldErrors,
            String path,
            Instant timestamp
    ) {}
}
