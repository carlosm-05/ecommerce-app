package com.uniminuto.ecommerce;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/** Verifica que la aplicacion arranca (usa una BD H2 en memoria para no tocar ./data). */
@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:testdb")
class EcommerceApiApplicationTests {

	@Test
	void contextLoads() {
	}

}
