# E-Commerce API (Spring Boot)

Backend REST de la **App E-Commerce en Flutter**, proyecto final de Aplicaciones Móviles (UNIMINUTO, Ingeniería de Sistemas).

**Stack:** Java 17 · Spring Boot 4 · Spring Security + JWT · Spring Data JPA (Hibernate) · H2 o MySQL · Bean Validation · JavaMail · Swagger (springdoc)

---

## 1. Cómo ejecutarlo

Necesitas **Java 17 o superior**. No hay que instalar Maven porque el proyecto trae el wrapper (`mvnw`).

```bash
# Windows
mvnw.cmd spring-boot:run

# Linux / macOS
./mvnw spring-boot:run
```

Cuando arranca:

| Qué | URL |
|---|---|
| API | http://localhost:8080 |
| Swagger (probar endpoints) | http://localhost:8080/swagger-ui.html |
| Consola H2 (ver tablas) | http://localhost:8080/h2-console (JDBC URL `jdbc:h2:file:./data/ecommerce`, usuario `sa`, sin contraseña) |

La primera vez carga **datos de prueba**: 5 categorías, 20 productos, 4 banners y un usuario de prueba:

- usuario: `demo` (o correo `demo@ecommerce.test`)
- contraseña: `Demo12345`

> Para empezar con la base de datos vacía, borra la carpeta `data/`.

### Usar Supabase (PostgreSQL en la nube)

La API lee un archivo **`.env`** en la carpeta del proyecto. Si ahí hay un `DB_URL`, se conecta a esa base; si no, usa H2.

1. En Supabase ve a **Project Settings → Database → Connection string → JDBC** y copia la del **Session pooler**. Funciona en redes sin IPv6, a diferencia de la conexión directa.
2. Crea el archivo `.env` (puedes partir de `.env.example`):
   ```properties
   DB_URL=jdbc:postgresql://aws-0-us-east-2.pooler.supabase.com:5432/postgres?sslmode=require
   DB_USERNAME=postgres.<id-del-proyecto>
   DB_PASSWORD=<tu-contraseña>
   DB_POOL_SIZE=5
   H2_CONSOLE=false
   ```
3. Arranca como siempre con `mvnw.cmd spring-boot:run`. La primera vez se crean las 8 tablas en el esquema `public` y se cargan los datos de prueba. Puedes verlas en el **Table Editor** de Supabase.

> `DB_POOL_SIZE=5` mantiene pocas conexiones abiertas, porque el pooler del plan gratuito tiene un límite bajo.
> El `.env` está en `.gitignore`: **nunca subas la contraseña a GitHub**.

### Usar MySQL en vez de H2

```sql
CREATE DATABASE ecommerce;
```
```bash
mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=mysql
```
El usuario y la contraseña se toman de `DB_USERNAME` y `DB_PASSWORD` (por defecto `root` / `root`). Las tablas se crean solas.

### Generar el .jar

```bash
mvnw.cmd clean package
java -jar target/ecommerce-api-0.0.1-SNAPSHOT.jar
```

### Con Docker (API + MySQL + bandeja de correo)

Solo necesitas [Docker Desktop](https://www.docker.com/products/docker-desktop/). No hace falta tener Java ni MySQL instalados.

```bash
docker compose up -d --build
```

| Servicio | URL | Qué es |
|---|---|---|
| `api` | http://localhost:8080 | La API, con Swagger en `/swagger-ui.html` |
| `db` | `localhost:3307` | MySQL 8.4 (usuario `ecommerce` / `ecommerce123`). Los datos se guardan en el volumen `mysql-data` |
| `mailpit` | http://localhost:8025 | Bandeja web donde llegan los correos de "Olvidé mi contraseña" |

La primera vez tarda unos minutos porque descarga las imágenes y compila el proyecto. Comandos útiles:

```bash
docker compose logs -f api      # ver la consola de la API
docker compose down             # apagar todo (conserva los datos)
docker compose down -v          # apagar y BORRAR la base de datos
docker compose up -d --build    # reconstruir después de cambiar el código
```

**Para cambiar contraseñas, el secreto JWT o usar Gmail:** copia `.env.example` como `.env` y edítalo; `docker compose` lo lee solo.

**Solo la API, sin MySQL** (usa H2 dentro del contenedor):
```bash
docker build -t ecommerce-api .
docker run -p 8080:8080 -v ecommerce-h2:/app/data ecommerce-api
```

---

## 2. Conectar desde Flutter

| Dónde corre la app | URL base |
|---|---|
| Emulador Android | `http://10.0.2.2:8080` |
| Simulador iOS / Flutter Web / Windows | `http://localhost:8080` |
| Celular físico (misma red WiFi) | `http://<IP-de-tu-PC>:8080` (ej. `http://192.168.1.10:8080`) |

> **Android y HTTP:** como la API no usa HTTPS, agrega `android:usesCleartextTraffic="true"` a la etiqueta `<application>` de `android/app/src/main/AndroidManifest.xml`.

**Flujo del JWT:**
1. `POST /auth/login` devuelve `token`. Guárdalo con `flutter_secure_storage` (o `shared_preferences`).
2. Envíalo en cada petición protegida: `Authorization: Bearer <token>`.
3. Si alguna respuesta es **401**, borra el token y manda al usuario al Login.
4. Para cerrar sesión: `POST /auth/logout` y luego borra el token local.

---

## 3. Endpoints

🔓 = público · 🔒 = requiere `Authorization: Bearer <token>`

### Autenticación
| Método | Ruta | | Descripción |
|---|---|---|---|
| POST | `/auth/register` | 🔓 | Registro. Responde **201** con el usuario (sin token, la app vuelve al Login) |
| POST | `/auth/login` | 🔓 | Login con username **o** correo. Devuelve el JWT |
| POST | `/auth/logout` | 🔒 | Invalida el token |
| GET | `/auth/check-username?username=x` | 🔓 | `{ "available": true/false }` |
| GET | `/auth/check-email?email=x` | 🔓 | `{ "available": true/false }` |
| POST | `/auth/forgot-password` | 🔓 | Envía el enlace de recuperación al correo |
| POST | `/auth/reset-password` | 🔓 | Cambia la contraseña con el token del enlace |

### Perfil
| Método | Ruta | | Descripción |
|---|---|---|---|
| GET | `/users/me` | 🔒 | Mis datos (avatar, nombre completo, username, correo) |
| PUT | `/users/me` | 🔒 | Editar nombre, apellidos, username (y opcionalmente `avatarUrl`) |
| PUT | `/users/me/password` | 🔒 | Cambiar contraseña (`currentPassword`, `newPassword`, `confirmPassword`) |

### Catálogo (Home y Detalle)
| Método | Ruta | | Descripción |
|---|---|---|---|
| GET | `/banners` | 🔓 | Imágenes del carrusel |
| GET | `/categories` | 🔓 | Categorías para los chips. El chip "Todos" es no enviar `categoryId` |
| GET | `/products?search=&categoryId=` | 🔓 | Lista de productos. Ambos filtros son opcionales y se pueden combinar |
| GET | `/products/{id}` | 🔓 | Detalle del producto |

### Carrito
Todas las operaciones devuelven el carrito completo, ya con el resumen calculado.

| Método | Ruta | | Descripción |
|---|---|---|---|
| GET | `/cart` | 🔒 | Ítems y resumen |
| POST | `/cart/items` | 🔒 | `{ "productId": 1, "quantity": 2 }`. Si el producto ya está, suma la cantidad |
| PATCH | `/cart/items/{itemId}` | 🔒 | `{ "quantity": 3 }`, para los botones + / − |
| DELETE | `/cart/items/{itemId}` | 🔒 | Elimina el ítem |
| DELETE | `/cart` | 🔒 | Vacía el carrito |

Resumen (`summary`): `subtotal`, `taxRate` (0.19), `tax` (IVA), `shipping` y `total`.
El envío cuesta **$12.000** y es **gratis desde $200.000**. Se puede cambiar en `application.properties` (`app.cart.*`).

### Pedidos
| Método | Ruta | | Descripción |
|---|---|---|---|
| POST | `/orders/checkout` | 🔒 | "Proceder al pago" (simulado): crea el pedido, descuenta el stock y vacía el carrito. Body opcional `{ "shippingAddress": "...", "paymentMethod": "TARJETA" }` |
| GET | `/orders` | 🔒 | Mis pedidos, del más reciente al más antiguo |
| GET | `/orders/{id}` | 🔒 | Detalle de un pedido |

---

## 4. Ejemplos

**Login**
```http
POST /auth/login
Content-Type: application/json

{ "usernameOrEmail": "demo", "password": "Demo12345" }
```
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": { "id": 1, "firstName": "Usuario", "lastName": "Demo", "fullName": "Usuario Demo",
            "username": "demo", "email": "demo@ecommerce.test", "avatarUrl": "https://ui-avatars.com/...",
            "createdAt": "2026-11-15T22:00:00Z" }
}
```

**Formato de error.** Siempre es el mismo, así en Flutter puedes mostrar los errores debajo de cada campo:
```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Hay errores en el formulario",
  "fieldErrors": {
    "email": "El formato del correo no es válido",
    "password": "La contraseña debe tener mínimo 8 caracteres"
  },
  "path": "/auth/register",
  "timestamp": "2026-11-15T22:00:00Z"
}
```
En `TextFormField`: `errorText: fieldErrors['email']`. El `message` general va en un `SnackBar`.

| Código | Cuándo |
|---|---|
| 400 | Validación fallida, contraseñas no coinciden, sin stock, carrito vacío, enlace de recuperación inválido |
| 401 | Credenciales incorrectas, o token ausente, inválido, expirado o cerrado con logout |
| 404 | Producto, ítem o pedido no existe |
| 409 | Username o correo ya registrados |

---

## 5. Recuperación de contraseña

1. La app llama a `POST /auth/forgot-password` con `{ "email": "..." }`.
2. El backend genera un token aleatorio de un solo uso que **vence en 30 minutos**. En la base de datos solo se guarda su hash SHA-256.
3. Se envía un correo con el enlace `http://localhost:8080/reset-password.html?token=...`.
4. Esa página (la sirve el mismo backend) pide la nueva contraseña, valida que tenga mínimo 8 caracteres y que coincida, y llama a `POST /auth/reset-password`.
5. Al cambiarla se cierran todas las sesiones abiertas del usuario.

**Sin configurar correo:** el enlace se imprime en la consola del backend (busca `Enlace de recuperación`). Con eso basta para la demo.

**Con correo real:** configura las variables de entorno antes de arrancar.

```bash
# Mailtrap (recomendado para pruebas: https://mailtrap.io, Email Testing → SMTP)
set MAIL_HOST=sandbox.smtp.mailtrap.io
set MAIL_PORT=2525
set MAIL_USERNAME=<usuario de mailtrap>
set MAIL_PASSWORD=<password de mailtrap>

# Gmail: necesitas una "contraseña de aplicación" (Cuenta de Google → Seguridad → Verificación en 2 pasos)
set MAIL_HOST=smtp.gmail.com
set MAIL_PORT=587
set MAIL_USERNAME=tucorreo@gmail.com
set MAIL_PASSWORD=<contraseña de aplicación>
set MAIL_FROM=tucorreo@gmail.com
```

**Si prefieres que el enlace abra la app Flutter** en vez de la página web, cambia
`RESET_PASSWORD_URL=ecommerceapp://reset-password?token=` y maneja ese deep link en Flutter (por ejemplo con `app_links`).

---

## 6. Arquitectura

```
src/main/java/com/uniminuto/ecommerce
├── config/        SecurityConfig (JWT, CORS, rutas públicas), OpenApiConfig (Swagger), DataSeeder (datos de prueba)
├── security/      JwtService (genera/valida tokens), JwtAuthFilter (lee el header Authorization), AuthUser
├── controller/    Endpoints REST: Auth, User, Catalog, Cart, Order
├── service/       Lógica de negocio: AuthService, UserService, CatalogService, CartService, OrderService, MailService
├── repository/    Interfaces Spring Data JPA
├── entity/        Tablas: User, Category, Product, Banner, CartItem, Order, OrderItem, PasswordResetToken
├── dto/           Objetos de entrada y salida (records) con sus validaciones
└── exception/     ApiException + GlobalExceptionHandler (formato único de error)
```

**Modelo de datos**

```
users ──< cart_items >── products >── categories
  │
  ├──< orders ──< order_items     (copia del nombre y precio al momento de comprar)
  └──< password_reset_tokens
banners
```

**Decisiones de diseño (útiles para el documento técnico):**
- **Contraseñas** con BCrypt; nunca se guardan en texto plano.
- **JWT stateless** firmado con HS256 y vigente 24 h. Incluye un claim `ver` (versión): con `logout` se incrementa la versión del usuario y todos sus tokens anteriores dejan de servir, sin necesidad de una lista negra.
- **Los totales los calcula el servidor**, así el cliente no puede manipular precios ni el IVA.
- **El checkout es transaccional**: valida el stock, crea el pedido, descuenta el inventario y vacía el carrito en una sola operación.
- **`OrderItem` guarda una copia** del nombre y precio, así si el producto cambia después el historial de pedidos no se altera.
- **`forgot-password` siempre responde lo mismo**, exista o no el correo, para no revelar qué cuentas están registradas.
- **Contraseña mínima:** el enunciado pide 6 caracteres en el Login y 8 en el Registro. Por eso el login acepta desde 6 y el registro, el cambio y la recuperación de contraseña exigen 8.

---

## 7. Configuración (`application.properties`)

| Propiedad / variable de entorno | Por defecto | Para qué |
|---|---|---|
| `PORT` | 8080 | Puerto |
| `JWT_SECRET` | (valor de desarrollo) | Secreto para firmar los tokens. **Cámbialo** (mínimo 32 caracteres) |
| `JWT_EXPIRATION_MINUTES` | 1440 | Duración del token |
| `app.cart.tax-rate` | 0.19 | IVA |
| `app.cart.shipping-cost` | 12000 | Costo de envío |
| `app.cart.free-shipping-from` | 200000 | Envío gratis desde este subtotal |
| `RESET_PASSWORD_URL` | `http://localhost:8080/reset-password.html?token=` | Enlace del correo |
| `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM` | vacío | SMTP |

La colección de Postman `postman_collection.json` trae todos los endpoints. Al hacer Login guarda el token sola.
