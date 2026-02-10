<?php
// backend/api/epp/create.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

try {
    // 1. Auth Check
    AuthMiddleware::validate();

    // 2. DB Connection
    $database = new Database();
    $db = $database->getConnection();

    // 3. Get Data
    $raw = file_get_contents("php://input");
    $data = json_decode($raw);

    if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
        http_response_code(400);
        echo json_encode(["message" => "Datos JSON inválidos o vacíos."]);
        exit();
    }

    // 4. Validate Required Fields
    $required = [
        'name', 'type', 'brand_id', 'category_id', 'size', 'reference', 
        'manufacturer', 'serial', 'fab_date', 'exp_date', 'buy_date', 
        'life_months', 'description'
    ];
    
    $missing = [];
    foreach ($required as $field) {
        if (empty($data->$field)) {
            $missing[] = $field;
        }
    }

    if (!empty($missing)) {
        http_response_code(400);
        echo json_encode(["message" => "Datos incompletos.", "missing_fields" => $missing]);
        exit();
    }

    // Asegurar que existan las secuencias que usa fn_insertar_epp
    try {
        $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_epp");
        $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_inventario");
        $db->query("SELECT setval('seq_epp', GREATEST(COALESCE((SELECT MAX(id_epp) FROM tab_epp), 0) + 1, 1))");
        $db->query("SELECT setval('seq_inventario', GREATEST(COALESCE((SELECT MAX(id_inventario) FROM inventario_epp), 0) + 1, 1))");
    } catch (PDOException $seqEx) {
        // Si las tablas no existen, la función dará error claro
    }

    // Llamar a la función fn_insertar_epp (database/functions/Función Insertar EPP.sql)
    $query = "SELECT fn_insertar_epp(
        :p_id_marca,
        :p_id_categoria,
        :p_talla_epp,
        :p_nom_epp,
        :p_tipo_epp,
        :p_referencia_epp,
        :p_fabricante_epp,
        :p_nro_serie_epp,
        :p_descripcion_epp,
        :p_fecha_fabricacion_epp,
        :p_fecha_vencimiento_epp,
        :p_fecha_compra_epp,
        :p_vida_util_meses
    ) as id";

    $stmt = $db->prepare($query);

    $p_id_marca = (int)$data->brand_id;
    $p_id_categoria = (int)$data->category_id;
    $p_talla_epp = trim($data->size ?? '');
    $p_nom_epp = trim($data->name ?? '');
    $p_tipo_epp = trim($data->type ?? '');
    $p_referencia_epp = trim($data->reference ?? '');
    $p_fabricante_epp = trim($data->manufacturer ?? '');
    $p_nro_serie_epp = trim($data->serial ?? '');
    $p_descripcion_epp = trim($data->description ?? '');
    $p_fecha_fabricacion_epp = $data->fab_date ?? '';
    $p_fecha_vencimiento_epp = $data->exp_date ?? '';
    $p_fecha_compra_epp = $data->buy_date ?? '';
    $p_vida_util_meses = (int)$data->life_months;

    $stmt->bindParam(":p_id_marca", $p_id_marca, PDO::PARAM_INT);
    $stmt->bindParam(":p_id_categoria", $p_id_categoria, PDO::PARAM_INT);
    $stmt->bindParam(":p_talla_epp", $p_talla_epp);
    $stmt->bindParam(":p_nom_epp", $p_nom_epp);
    $stmt->bindParam(":p_tipo_epp", $p_tipo_epp);
    $stmt->bindParam(":p_referencia_epp", $p_referencia_epp);
    $stmt->bindParam(":p_fabricante_epp", $p_fabricante_epp);
    $stmt->bindParam(":p_nro_serie_epp", $p_nro_serie_epp);
    $stmt->bindParam(":p_descripcion_epp", $p_descripcion_epp);
    $stmt->bindParam(":p_fecha_fabricacion_epp", $p_fecha_fabricacion_epp);
    $stmt->bindParam(":p_fecha_vencimiento_epp", $p_fecha_vencimiento_epp);
    $stmt->bindParam(":p_fecha_compra_epp", $p_fecha_compra_epp);
    $stmt->bindParam(":p_vida_util_meses", $p_vida_util_meses, PDO::PARAM_INT);

    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $nextId = (int)$row['id'];

    http_response_code(201);
    echo json_encode(["message" => "EPP creado exitosamente.", "id" => $nextId]);

} catch (PDOException $e) {
    $code = $e->getCode();
    $msg = $e->getMessage();
    if ($code == 23505) {
        http_response_code(400);
        echo json_encode(["message" => "El número de serie ya existe."]);
    } elseif (strpos($msg, 'seq_epp') !== false || strpos($msg, 'seq_inventario') !== false) {
        http_response_code(500);
        echo json_encode(["message" => "Error de secuencias. Ejecute database/setup_sequences.sql en PostgreSQL."]);
    } elseif (strpos($msg, 'fn_insertar_epp') !== false && strpos($msg, 'does not exist') !== false) {
        http_response_code(500);
        echo json_encode(["message" => "La función fn_insertar_epp no existe. Ejecute database/functions/Función Insertar EPP.sql"]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => $msg]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
?>
