package com.uniminuto.ecommerce.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

import java.util.Map;

/** Excepción de negocio: se traduce a JSON en {@link GlobalExceptionHandler}. */
@Getter
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final Map<String, String> fieldErrors;

    public ApiException(HttpStatus status, String message) {
        this(status, message, Map.of());
    }

    public ApiException(HttpStatus status, String message, Map<String, String> fieldErrors) {
        super(message);
        this.status = status;
        this.fieldErrors = fieldErrors;
    }

    public static ApiException notFound(String message) {
        return new ApiException(HttpStatus.NOT_FOUND, message);
    }

    public static ApiException badRequest(String message) {
        return new ApiException(HttpStatus.BAD_REQUEST, message);
    }

    /** Error de validacion asociado a un campo concreto del formulario. */
    public static ApiException field(HttpStatus status, String field, String message) {
        return new ApiException(status, message, Map.of(field, message));
    }
}
