package com.uniminuto.ecommerce.repository;

import com.uniminuto.ecommerce.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findAllByOrderByNameAsc();
    List<Product> findByNameContainingIgnoreCaseOrderByNameAsc(String name);
    List<Product> findByCategoryIdOrderByNameAsc(Long categoryId);
    List<Product> findByCategoryIdAndNameContainingIgnoreCaseOrderByNameAsc(Long categoryId, String name);
}
