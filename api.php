<?php
/**
 * PUNTO EXPRESO — CAFETERÍA (TÚQUERRES, NARIÑO)
 * API Backend para la integración de la Página Web con la Base de Datos MySQL
 * Permite: Registro, Consulta, Creación de Pedidos, Detalle y Reseñas
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/conexion.php';

$accion = $_GET['accion'] ?? '';

try {
    switch ($accion) {
        // -------------------------------------------------------------
        // ESTADO DE LA CONEXIÓN
        // -------------------------------------------------------------
        case 'estado':
            echo json_encode([
                'exito' => true,
                'servidor' => 'PHP ' . phpversion(),
                'motor' => 'MySQL (PDO Conectado con éxito)',
                'base_datos' => 'punto_expreso_db',
                'timestamp' => date('Y-m-d H:i:s')
            ], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // CONSULTA DE PRODUCTOS
        // -------------------------------------------------------------
        case 'obtener_productos':
            $stmt = $pdo->query("SELECT * FROM productos ORDER BY categoria ASC, id_producto ASC");
            $productos = $stmt->fetchAll();
            echo json_encode(['exito' => true, 'datos' => $productos], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // CONSULTA DE CLIENTES REGISTRADOS
        // -------------------------------------------------------------
        case 'obtener_clientes':
            $stmt = $pdo->query("SELECT * FROM clientes ORDER BY id_cliente DESC");
            $clientes = $stmt->fetchAll();
            echo json_encode(['exito' => true, 'datos' => $clientes], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // CONSULTA DE PEDIDOS Y SUS DETALLES
        // -------------------------------------------------------------
        case 'obtener_pedidos':
            $stmt = $pdo->query("
                SELECT 
                    p.id_pedido,
                    p.id_cliente,
                    CONCAT(c.nombre, ' ', c.apellido) AS cliente_nombre,
                    c.correo,
                    c.telefono,
                    p.fecha_pedido,
                    p.total,
                    p.estado
                FROM pedidos p
                INNER JOIN clientes c ON p.id_cliente = c.id_cliente
                ORDER BY p.id_pedido DESC
            ");
            $pedidos = $stmt->fetchAll();

            // Asociar los detalles de cada pedido
            $stmtDetalles = $pdo->query("
                SELECT 
                    dp.id_detalle,
                    dp.id_pedido,
                    dp.id_producto,
                    pr.nombre_producto,
                    pr.categoria,
                    dp.cantidad,
                    dp.subtotal
                FROM detalle_pedido dp
                INNER JOIN productos pr ON dp.id_producto = pr.id_producto
            ");
            $detalles = $stmtDetalles->fetchAll();

            $detallesPorPedido = [];
            foreach ($detalles as $det) {
                $detallesPorPedido[$det['id_pedido']][] = $det;
            }

            foreach ($pedidos as &$ped) {
                $ped['detalles'] = $detallesPorPedido[$ped['id_pedido']] ?? [];
            }

            echo json_encode(['exito' => true, 'datos' => $pedidos], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // CONSULTA DE OPINIONES
        // -------------------------------------------------------------
        case 'obtener_opiniones':
            $stmt = $pdo->query("
                SELECT 
                    o.id_opinion,
                    o.id_cliente,
                    CONCAT(c.nombre, ' ', c.apellido) AS cliente_nombre,
                    o.calificacion,
                    o.comentario,
                    o.fecha
                FROM opiniones o
                INNER JOIN clientes c ON o.id_cliente = c.id_cliente
                ORDER BY o.id_opinion DESC
            ");
            $opiniones = $stmt->fetchAll();
            echo json_encode(['exito' => true, 'datos' => $opiniones], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // REGISTRO DE NUEVO CLIENTE (POST)
        // -------------------------------------------------------------
        case 'registrar_cliente':
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                throw new Exception('Método HTTP no permitido. Debe ser POST.');
            }

            $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
            $nombre = trim($input['nombre'] ?? '');
            $apellido = trim($input['apellido'] ?? '');
            $correo = trim($input['correo'] ?? '');
            $telefono = trim($input['telefono'] ?? '');

            if (empty($nombre) || empty($apellido) || empty($correo) || empty($telefono)) {
                throw new Exception('Todos los campos del cliente son obligatorios.');
            }

            if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) {
                throw new Exception('El formato del correo electrónico no es válido.');
            }

            // Validar si el correo ya existe
            $check = $pdo->prepare("SELECT id_cliente FROM clientes WHERE correo = ?");
            $check->execute([$correo]);
            if ($check->fetch()) {
                throw new Exception('El correo ingresado ya se encuentra registrado.');
            }

            $stmt = $pdo->prepare("
                INSERT INTO clientes (nombre, apellido, correo, telefono, fecha_registro) 
                VALUES (?, ?, ?, ?, CURRENT_DATE)
            ");
            $stmt->execute([$nombre, $apellido, $correo, $telefono]);
            $nuevoId = $pdo->lastInsertId();

            echo json_encode([
                'exito' => true,
                'mensaje' => 'Cliente registrado exitosamente en la base de datos.',
                'id_cliente' => (int)$nuevoId,
                'cliente' => [
                    'id_cliente' => (int)$nuevoId,
                    'nombre' => $nombre,
                    'apellido' => $apellido,
                    'correo' => $correo,
                    'telefono' => $telefono,
                    'fecha_registro' => date('Y-m-d')
                ]
            ], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // GENERACIÓN DE PEDIDO Y REGISTRO EN DETALLE_PEDIDO (POST)
        // -------------------------------------------------------------
        case 'crear_pedido':
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                throw new Exception('Método HTTP no permitido. Debe ser POST.');
            }

            $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
            $idCliente = (int)($input['id_cliente'] ?? 0);
            $items = $input['items'] ?? [];

            if ($idCliente <= 0) {
                throw new Exception('Debe seleccionar o registrar un cliente válido.');
            }

            if (empty($items) || !is_array($items)) {
                throw new Exception('El pedido debe contener al menos un producto.');
            }

            // Iniciar transacción atómica
            $pdo->beginTransaction();

            // Calcular total y validar existencia de productos
            $totalCalculado = 0;
            $itemsValidados = [];

            foreach ($items as $item) {
                $idProd = (int)($item['id_producto'] ?? 0);
                $cant = (int)($item['cantidad'] ?? 1);

                if ($idProd <= 0 || $cant <= 0) continue;

                $stmtProd = $pdo->prepare("SELECT id_producto, nombre_producto, precio FROM productos WHERE id_producto = ?");
                $stmtProd->execute([$idProd]);
                $prod = $stmtProd->fetch();

                if (!$prod) {
                    throw new Exception("El producto con ID {$idProd} no existe en el catálogo.");
                }

                $subtotal = $prod['precio'] * $cant;
                $totalCalculado += $subtotal;

                $itemsValidados[] = [
                    'id_producto' => $idProd,
                    'nombre_producto' => $prod['nombre_producto'],
                    'cantidad' => $cant,
                    'subtotal' => $subtotal
                ];
            }

            if (empty($itemsValidados)) {
                throw new Exception('No hay productos válidos en el carrito.');
            }

            // Insertar en tabla PEDIDOS (PK id_pedido, FK id_cliente)
            $stmtPed = $pdo->prepare("
                INSERT INTO pedidos (id_cliente, fecha_pedido, total, estado) 
                VALUES (?, CURRENT_DATE, ?, 'Pendiente')
            ");
            $stmtPed->execute([$idCliente, $totalCalculado]);
            $idPedido = $pdo->lastInsertId();

            // Insertar en tabla DETALLE_PEDIDO
            $stmtDet = $pdo->prepare("
                INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, subtotal) 
                VALUES (?, ?, ?, ?)
            ");
            foreach ($itemsValidados as $iv) {
                $stmtDet->execute([$idPedido, $iv['id_producto'], $iv['cantidad'], $iv['subtotal']]);
            }

            // Confirmar transacción
            $pdo->commit();

            echo json_encode([
                'exito' => true,
                'mensaje' => 'Pedido registrado satisfactoriamente con su respectivo desglose en DETALLE_PEDIDO.',
                'id_pedido' => (int)$idPedido,
                'total' => $totalCalculado,
                'cantidad_items' => count($itemsValidados)
            ], JSON_UNESCAPED_UNICODE);
            break;

        // -------------------------------------------------------------
        // REGISTRO DE OPINIÓN / RESEÑA (POST)
        // -------------------------------------------------------------
        case 'registrar_opinion':
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                throw new Exception('Método HTTP no permitido. Debe ser POST.');
            }

            $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
            $idCliente = (int)($input['id_cliente'] ?? 0);
            $calificacion = (int)($input['calificacion'] ?? 5);
            $comentario = trim($input['comentario'] ?? '');

            if ($idCliente <= 0) {
                throw new Exception('Debe especificar un cliente válido para la reseña.');
            }

            if ($calificacion < 1 || $calificacion > 5) {
                throw new Exception('La calificación debe estar entre 1 y 5 estrellas.');
            }

            if (empty($comentario)) {
                throw new Exception('Por favor ingrese un comentario sobre su experiencia.');
            }

            $stmt = $pdo->prepare("
                INSERT INTO opiniones (id_cliente, calificacion, comentario, fecha) 
                VALUES (?, ?, ?, CURRENT_DATE)
            ");
            $stmt->execute([$idCliente, $calificacion, $comentario]);
            $idOpinion = $pdo->lastInsertId();

            echo json_encode([
                'exito' => true,
                'mensaje' => 'Opinión registrada con éxito en la base de datos.',
                'id_opinion' => (int)$idOpinion
            ], JSON_UNESCAPED_UNICODE);
            break;

        default:
            echo json_encode([
                'exito' => false,
                'mensaje' => 'Acción no especificada o no válida.',
                'acciones_disponibles' => [
                    'estado',
                    'obtener_productos',
                    'obtener_clientes',
                    'obtener_pedidos',
                    'obtener_opiniones',
                    'registrar_cliente (POST)',
                    'crear_pedido (POST)',
                    'registrar_opinion (POST)'
                ]
            ], JSON_UNESCAPED_UNICODE);
            break;
    }
} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(400);
    echo json_encode([
        'exito' => false,
        'mensaje' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
