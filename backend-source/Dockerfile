# syntax=docker/dockerfile:1

# ------------------------------------------------------------ Etapa 1: compilar
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

# Primero solo el pom: Docker cachea las dependencias y no las vuelve a bajar
# si solo cambia el código fuente.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q -DskipTests package \
    && cp target/ecommerce-api-*.jar app.jar

# ------------------------------------------------------------ Etapa 2: ejecutar
FROM eclipse-temurin:17-jre
WORKDIR /app

# Usuario sin privilegios (buena práctica de seguridad)
RUN groupadd --system spring && useradd --system --gid spring spring \
    && mkdir -p /app/data && chown -R spring:spring /app
USER spring

COPY --from=build --chown=spring:spring /build/app.jar app.jar

# Carpeta de la base H2 (cuando no se usa MySQL)
VOLUME /app/data

EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
