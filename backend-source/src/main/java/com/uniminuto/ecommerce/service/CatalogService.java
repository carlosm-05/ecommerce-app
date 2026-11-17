package com.uniminuto.ecommerce.service;

import com.uniminuto.ecommerce.dto.CatalogDtos.BannerResponse;
import com.uniminuto.ecommerce.dto.CatalogDtos.CategoryResponse;
import com.uniminuto.ecommerce.dto.CatalogDtos.ProductResponse;
import com.uniminuto.ecommerce.entity.Product;
import com.uniminuto.ecommerce.exception.ApiException;
import com.uniminuto.ecommerce.repository.BannerRepository;
import com.uniminuto.ecommerce.repository.CategoryRepository;
import com.uniminuto.ecommerce.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class CatalogService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final BannerRepository bannerRepository;

    public CatalogService(ProductRepository productRepository, CategoryRepository categoryRepository,
                          BannerRepository bannerRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.bannerRepository = bannerRepository;
    }

    public List<CategoryResponse> categories() {
        return categoryRepository.findAllByOrderByIdAsc().stream().map(CategoryResponse::from).toList();
    }

    public List<BannerResponse> banners() {
        return bannerRepository.findAllByOrderBySortOrderAsc().stream().map(BannerResponse::from).toList();
    }

    /** Busca por nombre (parcial, sin importar mayúsculas) y/o filtra por categoría. Ambos opcionales. */
    public List<ProductResponse> products(String search, Long categoryId) {
        boolean hasSearch = search != null && !search.isBlank();
        String q = hasSearch ? search.trim() : null;

        List<Product> result;
        if (categoryId != null && hasSearch) {
            result = productRepository.findByCategoryIdAndNameContainingIgnoreCaseOrderByNameAsc(categoryId, q);
        } else if (categoryId != null) {
            result = productRepository.findByCategoryIdOrderByNameAsc(categoryId);
        } else if (hasSearch) {
            result = productRepository.findByNameContainingIgnoreCaseOrderByNameAsc(q);
        } else {
            result = productRepository.findAllByOrderByNameAsc();
        }
        return result.stream().map(ProductResponse::from).toList();
    }

    public ProductResponse product(Long id) {
        return productRepository.findById(id).map(ProductResponse::from)
                .orElseThrow(() -> ApiException.notFound("Producto no encontrado"));
    }
}
