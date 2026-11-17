package com.uniminuto.ecommerce.dto;

import com.uniminuto.ecommerce.entity.Banner;
import com.uniminuto.ecommerce.entity.Category;
import com.uniminuto.ecommerce.entity.Product;

import java.math.BigDecimal;

/** DTOs del catálogo: categorias, productos y banners. */
public final class CatalogDtos {

    private CatalogDtos() {}

    public record CategoryResponse(Long id, String name, String icon) {
        public static CategoryResponse from(Category c) {
            return new CategoryResponse(c.getId(), c.getName(), c.getIcon());
        }
    }

    public record ProductResponse(
            Long id,
            String name,
            String description,
            BigDecimal price,
            String imageUrl,
            int stock,
            Long categoryId,
            String categoryName
    ) {
        public static ProductResponse from(Product p) {
            return new ProductResponse(p.getId(), p.getName(), p.getDescription(), p.getPrice(),
                    p.getImageUrl(), p.getStock(), p.getCategory().getId(), p.getCategory().getName());
        }
    }

    public record BannerResponse(Long id, String imageUrl, String title) {
        public static BannerResponse from(Banner b) {
            return new BannerResponse(b.getId(), b.getImageUrl(), b.getTitle());
        }
    }
}
