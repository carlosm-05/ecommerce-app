package com.uniminuto.ecommerce.config;

import com.uniminuto.ecommerce.entity.Banner;
import com.uniminuto.ecommerce.entity.Category;
import com.uniminuto.ecommerce.entity.Product;
import com.uniminuto.ecommerce.entity.User;
import com.uniminuto.ecommerce.repository.BannerRepository;
import com.uniminuto.ecommerce.repository.CategoryRepository;
import com.uniminuto.ecommerce.repository.ProductRepository;
import com.uniminuto.ecommerce.repository.UserRepository;
import com.uniminuto.ecommerce.service.AuthService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/** Carga datos de prueba la primera vez que arranca (si no hay categorías). */
@Component
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final BannerRepository bannerRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(CategoryRepository categoryRepository, ProductRepository productRepository,
                      BannerRepository bannerRepository, UserRepository userRepository,
                      PasswordEncoder passwordEncoder) {
        this.categoryRepository = categoryRepository;
        this.productRepository = productRepository;
        this.bannerRepository = bannerRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (categoryRepository.count() > 0) {
            return;
        }
        log.info("Cargando datos de prueba...");

        Map<String, Category> c = new LinkedHashMap<>();
        c.put("Ropa", cat("Ropa", "checkroom"));
        c.put("Electrónica", cat("Electrónica", "devices"));
        c.put("Hogar", cat("Hogar", "chair"));
        c.put("Deportes", cat("Deportes", "sports_soccer"));
        c.put("Belleza", cat("Belleza", "spa"));

        // Ropa
        p("Camiseta básica algodón", "Camiseta unisex 100% algodón, cuello redondo, ideal para el día a día.", 39900, 50, c.get("Ropa"));
        p("Jean slim fit", "Jean azul oscuro de corte slim con elastano para mayor comodidad.", 119900, 30, c.get("Ropa"));
        p("Chaqueta impermeable", "Chaqueta liviana resistente al agua con capucha ajustable.", 189900, 15, c.get("Ropa"));
        p("Sudadera con capucha", "Sudadera perchada por dentro con bolsillo canguro.", 89900, 25, c.get("Ropa"));
        // Electrónica
        p("Audífonos inalámbricos", "Audífonos Bluetooth 5.3 con cancelación de ruido y 30 h de batería.", 249900, 20, c.get("Electrónica"));
        p("Smartwatch deportivo", "Reloj inteligente con GPS, ritmo cardiaco y resistencia al agua 5 ATM.", 329900, 12, c.get("Electrónica"));
        p("Parlante portátil", "Parlante Bluetooth resistente al agua con sonido 360°.", 159900, 18, c.get("Electrónica"));
        p("Teclado mecánico", "Teclado mecánico compacto con switches rojos e iluminación RGB.", 219900, 10, c.get("Electrónica"));
        // Hogar
        p("Lámpara de escritorio LED", "Lámpara LED regulable con 3 tonos de luz y puerto USB.", 79900, 22, c.get("Hogar"));
        p("Set de ollas antiadherentes", "Juego de 5 ollas con recubrimiento antiadherente y tapas de vidrio.", 299900, 8, c.get("Hogar"));
        p("Cafetera de goteo", "Cafetera de 12 tazas con filtro permanente y placa térmica.", 139900, 14, c.get("Hogar"));
        p("Cojín decorativo", "Cojín de 45x45 cm con funda lavable de lino.", 34900, 40, c.get("Hogar"));
        // Deportes
        p("Balón de fútbol", "Balón profesional tamaño 5, cosido a máquina.", 89900, 30, c.get("Deportes"));
        p("Mat de yoga", "Colchoneta antideslizante de 6 mm con correa de transporte.", 69900, 35, c.get("Deportes"));
        p("Mancuernas ajustables", "Par de mancuernas ajustables de 2 a 10 kg cada una.", 279900, 9, c.get("Deportes"));
        p("Botella térmica", "Botella de acero inoxidable de 750 ml, mantiene frío 24 h.", 49900, 45, c.get("Deportes"));
        // Belleza
        p("Crema hidratante facial", "Crema con ácido hialurónico para todo tipo de piel, 50 ml.", 59900, 28, c.get("Belleza"));
        p("Perfume floral", "Eau de parfum con notas florales y cítricas, 100 ml.", 199900, 11, c.get("Belleza"));
        p("Kit de brochas de maquillaje", "Set de 12 brochas de cerdas sintéticas con estuche.", 74900, 20, c.get("Belleza"));
        p("Protector solar SPF 50", "Protector solar de textura ligera, resistente al agua, 60 ml.", 54900, 33, c.get("Belleza"));

        String[] titles = {"Hasta 40% en electrónica", "Nueva colección de ropa", "Envío gratis desde $200.000", "Todo para tu hogar"};
        for (int i = 0; i < titles.length; i++) {
            bannerRepository.save(Banner.builder()
                    .imageUrl("https://picsum.photos/seed/banner" + (i + 1) + "/1200/500")
                    .title(titles[i])
                    .sortOrder(i + 1)
                    .build());
        }

        if (!userRepository.existsByUsernameIgnoreCase("demo")) {
            userRepository.save(User.builder()
                    .firstName("Usuario")
                    .lastName("Demo")
                    .username("demo")
                    .email("demo@ecommerce.test")
                    .passwordHash(passwordEncoder.encode("Demo12345"))
                    .avatarUrl(AuthService.defaultAvatar("Usuario", "Demo"))
                    .build());
        }
        log.info("Datos de prueba cargados: {} categorías, {} productos, usuario demo / Demo12345",
                categoryRepository.count(), productRepository.count());
    }

    private Category cat(String name, String icon) {
        return categoryRepository.save(Category.builder().name(name).icon(icon).build());
    }

    private void p(String name, String description, long price, int stock, Category category) {
        String seed = name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        productRepository.save(Product.builder()
                .name(name)
                .description(description)
                .price(BigDecimal.valueOf(price).setScale(2))
                .imageUrl("https://picsum.photos/seed/" + seed + "/600/600")
                .stock(stock)
                .category(category)
                .build());
    }
}
