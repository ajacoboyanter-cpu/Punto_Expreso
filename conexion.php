<?php
/**
 * PUNTO EXPRESO — CAFETERÍA (TÚQUERRES, NARIÑO)
 * Conexión a la base de datos MySQL con PDO
 * Proyecto Productivo SENATIC / Técnico en Programación de Software
 */

header('Content-Type: application/json; charset=utf-8');

$host = 'localhost';
$dbname = 'punto_expreso_db';
$usuario = 'root';
$password = ''; // Configuración estándar de XAMPP / WAMP

try {
    $opciones = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
    ];
    $pdo = new PDO("mysql:host={$host};dbname={$dbname};charset=utf8mb4", $usuario, $password, $opciones);
} catch (PDOException $e) {
    // Si la conexión falla, se puede retornar error o advertencia JSON
    http_response_code(500);
    echo json_encode([
        'exito' => false,
        'mensaje' => 'Error al conectar con la base de datos MySQL: ' . $e->getMessage(),
        'ayuda' => 'Asegúrese de haber iniciado el servicio MySQL en XAMPP y haber importado el archivo database.sql'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
?>
