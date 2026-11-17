package com.uniminuto.ecommerce.controller;

import io.swagger.v3.oas.annotations.Hidden;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Hidden
@RestController
public class HomeController {

    @GetMapping("/")
    public Map<String, String> home() {
        return Map.of(
                "name", "E-Commerce API",
                "status", "OK",
                "docs", "/swagger-ui.html");
    }
}
