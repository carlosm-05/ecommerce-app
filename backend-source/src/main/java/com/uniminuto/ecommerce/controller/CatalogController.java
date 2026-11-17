package com.uniminuto.ecommerce.controller;

import com.uniminuto.ecommerce.dto.CatalogDtos.BannerResponse;
import com.uniminuto.ecommerce.dto.CatalogDtos.CategoryResponse;
import com.uniminuto.ecommerce.dto.CatalogDtos.ProductResponse;
import com.uniminuto.ecommerce.service.CatalogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Catálogo", description = "Banners, categorías y productos (públicos, no requieren token)")
public class CatalogController {

    private final CatalogService catalogService;

    public CatalogController(CatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping("/banners")
    @Operation(summary = "Imágenes del carrusel del Home")
    public List<BannerResponse> banners() {
        return catalogService.banners();
    }

    @GetMapping("/categories")
    @Operation(summary = "Categorías para los chips del Home",
            description = "El chip \"Todos\" se maneja en la app: simplemente no envíes categoryId.")
    public List<CategoryResponse> categories() {
        return catalogService.categories();
    }

    @GetMapping("/products")
    @Operation(summary = "Listar productos", description = "Filtros opcionales: search (nombre) y categoryId.")
    public List<ProductResponse> products(@RequestParam(required = false) String search,
                                          @RequestParam(required = false) Long categoryId) {
        return catalogService.products(search, categoryId);
    }

    @GetMapping("/products/{id}")
    @Operation(summary = "Detalle de un producto")
    public ProductResponse product(@PathVariable Long id) {
        return catalogService.product(id);
    }
}
