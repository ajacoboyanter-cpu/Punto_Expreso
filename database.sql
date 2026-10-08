-- =====================================================================
-- PROYECTO PROM: PUNTO EXPRESO — CAFETERÍA (TÚQUERRES, NARIÑO)
-- INSTITUCIÓN EDUCATIVA INSTITUTO TERESIANO / SENATIC - SENA
-- FICHA: 3212667 — TÉCNICO EN PROGRAMACIÓN DE SOFTWARE
-- BASE DE DATOS RELACIONAL: punto_expreso_db
-- =====================================================================

-- 1. CREACIÓN DE LA BASE DE DATOS
CREATE DATABASE IF NOT EXISTS `punto_expreso_db`
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE `punto_expreso_db`;

-- Desactivar temporalmente revisión de llaves foráneas para reinicio limpio
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `opiniones`;
DROP TABLE IF EXISTS `detalle_pedido`;
DROP TABLE IF EXISTS `pedidos`;
DROP TABLE IF EXISTS `productos`;
DROP TABLE IF EXISTS `clientes`;
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 2. TABLA 1: CLIENTES
-- Almacena la información de los clientes registrados en la plataforma.
-- PK: id_cliente
-- =====================================================================
CREATE TABLE `clientes` (
    `id_cliente` INT NOT NULL AUTO_INCREMENT,
    `nombre` VARCHAR(50) NOT NULL,
    `apellido` VARCHAR(50) NOT NULL,
    `correo` VARCHAR(100) NOT NULL UNIQUE,
    `telefono` VARCHAR(20) NOT NULL,
    `fecha_registro` DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (`id_cliente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. TABLA 2: PRODUCTOS
-- Catálogo oficial de productos, bebidas, repostería y alimentos de la cafetería.
-- PK: id_producto
-- =====================================================================
CREATE TABLE `productos` (
    `id_producto` INT NOT NULL AUTO_INCREMENT,
    `nombre_producto` VARCHAR(100) NOT NULL,
    `categoria` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    `precio` DECIMAL(10,2) NOT NULL,
    `disponibilidad` ENUM('Disponible', 'Agotado') NOT NULL DEFAULT 'Disponible',
    PRIMARY KEY (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4. TABLA 3: PEDIDOS
-- Encabezado de los pedidos generados por los clientes en la web.
-- PK: id_pedido
-- FK: id_cliente -> clientes(id_cliente)
-- Relación: CLIENTES (1) -> PEDIDOS (N)
-- =====================================================================
CREATE TABLE `pedidos` (
    `id_pedido` INT NOT NULL AUTO_INCREMENT,
    `id_cliente` INT NOT NULL,
    `fecha_pedido` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `total` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `estado` ENUM('Pendiente', 'En preparación', 'Entregado', 'Cancelado') NOT NULL DEFAULT 'Pendiente',
    PRIMARY KEY (`id_pedido`),
    CONSTRAINT `fk_pedidos_cliente`
        FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 5. TABLA 4: DETALLE_PEDIDO
-- Tabla intermedia que resuelve la relación N:M entre PEDIDOS y PRODUCTOS.
-- Almacena cada ítem, su cantidad y el subtotal calculado.
-- PK: id_detalle
-- FK1: id_pedido -> pedidos(id_pedido)
-- FK2: id_producto -> productos(id_producto)
-- Relaciones: PEDIDOS (1) -> DETALLE_PEDIDO (N), PRODUCTOS (1) -> DETALLE_PEDIDO (N)
-- =====================================================================
CREATE TABLE `detalle_pedido` (
    `id_detalle` INT NOT NULL AUTO_INCREMENT,
    `id_pedido` INT NOT NULL,
    `id_producto` INT NOT NULL,
    `cantidad` INT NOT NULL DEFAULT 1,
    `subtotal` DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (`id_detalle`),
    CONSTRAINT `fk_detalle_pedido`
        FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT `fk_detalle_producto`
        FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 6. TABLA 5: OPINIONES
-- Reseñas y calificaciones (1 a 5 estrellas) enviadas por los clientes.
-- PK: id_opinion
-- FK: id_cliente -> clientes(id_cliente)
-- Relación: CLIENTES (1) -> OPINIONES (N)
-- =====================================================================
CREATE TABLE `opiniones` (
    `id_opinion` INT NOT NULL AUTO_INCREMENT,
    `id_cliente` INT NOT NULL,
    `calificacion` INT NOT NULL CHECK (`calificacion` BETWEEN 1 AND 5),
    `comentario` TEXT NOT NULL,
    `fecha` DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (`id_opinion`),
    CONSTRAINT `fk_opiniones_cliente`
        FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 7. INSERCIÓN DE DATOS DE EJEMPLO COHERENTES (DEMOSTRACIÓN ACADÉMICA)
-- =====================================================================

-- Inserción de Clientes de prueba
INSERT INTO `clientes` (`id_cliente`, `nombre`, `apellido`, `correo`, `telefono`, `fecha_registro`) VALUES
(1, 'Andrés', 'Yandar', 'andres@email.com', '3000000000', '2026-10-01'),
(2, 'María', 'Termal', 'maria@email.com', '3010000000', '2026-10-02'),
(3, 'Angie', 'Rosero', 'angie.rosero@email.com', '3153276522', '2026-10-03'),
(4, 'Melany', 'Tobar', 'melany.tobar@email.com', '3188803714', '2026-10-04'),
(5, 'Maicol', 'Díaz', 'maicol.diaz@email.com', '3184210112', '2026-10-05');

-- Inserción de Productos oficiales del proyecto
INSERT INTO `productos` (`id_producto`, `nombre_producto`, `categoria`, `descripcion`, `precio`, `disponibilidad`) VALUES
(1, 'Café Americano', 'Café', 'Café negro clásico preparado con agua caliente y espresso de grano seleccionado nariñense.', 5000.00, 'Disponible'),
(2, 'Latte', 'Café', 'Deliciosa combinación de café espresso suave con leche vaporizada y sutil capa de espuma.', 7000.00, 'Disponible'),
(3, 'Panadería Tradicional', 'Panadería', 'Pan artesanal recién salido del horno elaborado con recetas tradicionales y masa madre.', 4000.00, 'Disponible'),
(4, 'Pastelería de Autor', 'Pastelería', 'Porción selecta de pastel artesanal del día con rellenos y decoraciones especiales.', 6000.00, 'Disponible'),
(5, 'Café Especial', 'Café', 'Café de origen nariñense de estricta altura, con notas aromáticas florales y cítricas.', 5000.00, 'Disponible'),
(6, 'Cappuccino', 'Café', 'Equilibrio perfecto de café espresso, leche texturizada y abundante espuma cremosa.', 7000.00, 'Disponible'),
(7, 'Café con Leche', 'Café', 'Preparación cálida y reconfortante de café tradicional con leche entera fresca.', 6000.00, 'Disponible'),
(8, 'Chocolate Caliente', 'Bebidas', 'Chocolate tradicional de campo batido con leche espumosa y aroma a canela y clavos.', 7000.00, 'Disponible'),
(9, 'Té Gourmet', 'Bebidas', 'Variedad de infusiones aromáticas, frutos rojos y té verde servidos a temperatura perfecta.', 5000.00, 'Disponible'),
(10, 'Pan Artesanal', 'Panadería', 'Hogaza de pan crujiente por fuera y esponjosa por dentro, ideal para acompañar.', 4000.00, 'Disponible'),
(11, 'Croissant de Mantequilla', 'Panadería', 'Hojaldre francés crujiente horneado con mantequilla de primera calidad.', 6000.00, 'Disponible'),
(12, 'Pan de Queso', 'Panadería', 'Amasijo típico horneado con almidón de yuca y generosa cantidad de queso fresco.', 5000.00, 'Disponible'),
(13, 'Torta de Chocolate', 'Pastelería', 'Bizcocho húmedo de puro cacao con ganache oscuro y cobertura sedosa.', 8000.00, 'Disponible'),
(14, 'Cheesecake de Frutos Rojos', 'Pastelería', 'Tarta de queso crema suave sobre base de galleta crocante y salsa artesanal de mora y fresa.', 9000.00, 'Disponible'),
(15, 'Torta de Vainilla', 'Pastelería', 'Clásica torta suave perfumada con extracto de vainilla natural.', 8000.00, 'Disponible'),
(16, 'Desayuno Punto', 'Platos', 'Huevos al gusto, pan artesanal caliente, queso campesino, porción de fruta y café.', 12000.00, 'Disponible'),
(17, 'Almuerzo del Día', 'Platos', 'Plato balanceado con arroz, proteína a la plancha, ensalada de la huerta y sopa.', 16000.00, 'Disponible'),
(18, 'Cena Punto', 'Platos', 'Proteína ligera, vegetales salteados, acompañamiento caliente y bebida caliente.', 16000.00, 'Disponible'),
(19, 'Hamburguesa Punto', 'Comidas rápidas', 'Carne de res seleccionada, queso derretido, lechuga fresca, tomate y pan brioche.', 16000.00, 'Disponible'),
(20, 'Sandwich Especial', 'Comidas rápidas', 'Pan baguette artesanal, jamón seleccionado, doble queso, lechuga y aderezo de la casa.', 12000.00, 'Disponible'),
(21, 'Papas Fritas Crocantes', 'Comidas rápidas', 'Papas cultivadas en la sabana de Túquerres, doradas al punto exacto con sal marina.', 8000.00, 'Disponible'),
(22, 'Combo Infantil 1', 'Combos infantiles', 'Mini sandwich de jamón y queso, jugo natural de fruta y galleta artesanal de avena.', 10000.00, 'Disponible'),
(23, 'Combo Infantil 2', 'Combos infantiles', 'Porción de papas doradas, nuggets de pollo o mini hamburguesa y jugo o malteada.', 12000.00, 'Disponible'),
(24, 'Combo Infantil 3', 'Combos infantiles', 'Mini hamburguesa Punto, papas crocantes, jugo de naranja y porción de torta de chocolate.', 15000.00, 'Disponible');

-- Inserción de Pedidos de prueba
INSERT INTO `pedidos` (`id_pedido`, `id_cliente`, `fecha_pedido`, `total`, `estado`) VALUES
(1, 1, '2026-10-07', 12000.00, 'Pendiente'),
(2, 2, '2026-10-07', 7000.00, 'Entregado'),
(3, 3, '2026-10-07', 19000.00, 'En preparación'),
(4, 4, '2026-10-07', 15000.00, 'Entregado'),
(5, 5, '2026-10-07', 16000.00, 'Pendiente');

-- Inserción de Detalles de los pedidos de prueba
-- Pedido 1 (Andrés Yandar): 1 Café Americano ($5.000) + 1 Latte ($7.000) = $12.000
INSERT INTO `detalle_pedido` (`id_detalle`, `id_pedido`, `id_producto`, `cantidad`, `subtotal`) VALUES
(1, 1, 1, 1, 5000.00),
(2, 1, 2, 1, 7000.00),

-- Pedido 2 (María Termal): 1 Cappuccino ($7.000) = $7.000
(3, 2, 6, 1, 7000.00),

-- Pedido 3 (Angie Rosero): 1 Café Especial ($5.000) + 1 Pan de Queso ($5.000) + 1 Cheesecake ($9.000) = $19.000
(4, 3, 5, 1, 5000.00),
(5, 3, 12, 1, 5000.00),
(6, 3, 14, 1, 9000.00),

-- Pedido 4 (Melany Tobar): 1 Combo Infantil 3 ($15.000) = $15.000
(7, 4, 24, 1, 15000.00),

-- Pedido 5 (Maicol Díaz): 1 Hamburguesa Punto ($16.000) = $16.000
(8, 5, 19, 1, 16000.00);

-- Inserción de Opiniones / Reseñas de prueba
INSERT INTO `opiniones` (`id_opinion`, `id_cliente`, `calificacion`, `comentario`, `fecha`) VALUES
(1, 1, 5, 'Excelente atención y café. El aroma del café de altura de Nariño es inigualable.', '2026-10-07'),
(2, 2, 5, 'El latte y los panes artesanales estaban frescos y con un sabor delicioso. Muy recomendado.', '2026-10-07'),
(3, 3, 4, 'Un ambiente muy tranquilo y acogedor en Túquerres. Ideal para compartir en familia y trabajar.', '2026-10-07'),
(4, 4, 5, 'Los combos infantiles son muy completos y a los niños les encanta la presentación y sabor.', '2026-10-07'),
(5, 5, 5, 'La integración tecnológica de la cafetería facilita hacer pedidos rápidamente. Gran innovación.', '2026-10-07');

-- =====================================================================
-- 8. CONSULTAS SQL DE DEMOSTRACIÓN (PRUEBAS DE INTEGRIDAD Y REPORTES)
-- =====================================================================

-- Consulta 1: Listar pedidos completos con nombre de cliente y total
SELECT 
    p.id_pedido,
    CONCAT(c.nombre, ' ', c.apellido) AS cliente,
    c.telefono,
    p.fecha_pedido,
    p.total,
    p.estado
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
ORDER BY p.id_pedido DESC;

-- Consulta 2: Desglose de productos comprados en cada pedido
SELECT 
    dp.id_pedido,
    c.nombre AS cliente,
    pr.nombre_producto,
    pr.categoria,
    dp.cantidad,
    dp.subtotal
FROM detalle_pedido dp
INNER JOIN pedidos p ON dp.id_pedido = p.id_pedido
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
INNER JOIN productos pr ON dp.id_producto = pr.id_producto
ORDER BY dp.id_pedido, dp.id_detalle;

-- Consulta 3: Promedio de calificación y total de opiniones
SELECT 
    COUNT(o.id_opinion) AS total_opiniones,
    ROUND(AVG(o.calificacion), 2) AS calificacion_promedio
FROM opiniones o;
