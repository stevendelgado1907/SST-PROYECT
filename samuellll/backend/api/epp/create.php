<?php
// backend/api/epp/create.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

// Enable error reporting for debugging (puedes desactivar en producción)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Mantener referencia global para poder hacer rollback en los catch
$db = null;

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

    // Iniciar transacción para garantizar que EPP e inventario se guarden juntos
    $db->beginTransaction();

    // Asegurar que existan las secuencias y estén sincronizadas
    try {
        $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_epp");
        $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_inventario");
        // Sincronizar con el máximo ID actual para evitar conflictos en inserts manuales previos
        $db->query("SELECT setval('seq_epp', GREATEST(COALESCE((SELECT MAX(id_epp) FROM tab_epp), 0) + 1, 1), false)");
        $db->query("SELECT setval('seq_inventario', GREATEST(COALESCE((SELECT MAX(id_inventario) FROM inventario_epp), 0) + 1, 1), false)");
    } catch (PDOException $seqEx) {
        // Ignorar si hay error de permisos, pero loguear
        error_log("Error inicializando secuencias: " . $seqEx->getMessage());
    }

    // 5. Preparar datos para la función SQL directa (Pedido por el usuario)
    /**
     * Inserta un nuevo EPP en la tabla tab_epp
     * @param PDO $pdo Instancia de la conexión a la base de datos
     * @param array $data Arreglo asociativo con los datos del EPP
     * @return bool True si tuvo éxito, False si falló
     */
    function crearEPP(PDO $pdo, array $data) {
        try {
            $sql = "INSERT INTO tab_epp (
                        id_epp, id_marca, id_categoria, talla_epp, nom_epp, 
                        tipo_epp, referencia_epp, fabricante_epp, nro_serie_epp, 
                        descripcion_epp, fecha_fabricacion_epp, fecha_vencimiento_epp, 
                        fecha_compra_epp, vida_util_meses, estado_epp
                    ) VALUES (
                        :id_epp, :id_marca, :id_categoria, :talla_epp, :nom_epp, 
                        :tipo_epp, :referencia_epp, :fabricante_epp, :nro_serie_epp, 
                        :descripcion_epp, :fecha_fabricacion_epp, :fecha_vencimiento_epp, 
                        :fecha_compra_epp, :vida_util_meses, :estado_epp
                    )";
            $stmt = $pdo->prepare($sql);
            return $stmt->execute($data);
        } catch (PDOException $e) {
            error_log("Error al insertar EPP: " . $e->getMessage());
            throw $e;
        }
    }

    // Obtener el siguiente ID de la secuencia
    $resSeq = $db->query("SELECT nextval('seq_epp') as nextid");
    $nextEppId = $resSeq->fetch(PDO::FETCH_ASSOC)['nextid'];

    $datosEPP = [
        ':id_epp'                => $nextEppId,
        ':id_marca'              => (int)$data->brand_id,
        ':id_categoria'          => (int)$data->category_id,
        ':talla_epp'             => strtoupper(trim($data->size ?? '')),
        ':nom_epp'               => strtoupper(trim($data->name ?? '')),
        ':tipo_epp'              => strtoupper(trim($data->type ?? '')),
        ':referencia_epp'        => strtoupper(trim($data->reference ?? '')),
        ':fabricante_epp'        => ucwords(strtolower(trim($data->manufacturer ?? ''))),
        ':nro_serie_epp'         => strtoupper(trim($data->serial ?? '')),
        ':descripcion_epp'       => trim($data->description ?? ''),
        ':fecha_fabricacion_epp' => $data->fab_date ?? '',
        ':fecha_vencimiento_epp' => $data->exp_date ?? '',
        ':fecha_compra_epp'      => $data->buy_date ?? '',
        ':vida_util_meses'       => (int)$data->life_months,
        ':estado_epp'            => 'DISPONIBLE'
    ];

    if (crearEPP($db, $datosEPP)) {
        // Al usar SQL directo, insertamos manualmente en inventario para no romper la funcionalidad
        $qInv = "INSERT INTO inventario_epp (id_inventario, id_epp, stock_actual, stock_minimo, stock_maximo, punto_reorden)
                 VALUES (nextval('seq_inventario'), :id_epp, 1, 1, 10, 2)";
        $stInv = $db->prepare($qInv);
        $stInv->execute([':id_epp' => $nextEppId]);

        // Si todo sale bien, confirmamos la transacción
        $db->commit();

        http_response_code(201);
        echo json_encode([
            "status" => "success",
            "message" => "EPP creado exitosamente (SQL directo, con inventario inicial).", 
            "id" => $nextEppId
        ]);
    } else {
        // En teoría no deberíamos llegar aquí si lanzaramos excepción en crearEPP
        throw new Exception("Error al ejecutar el insert de EPP.");
    }

} catch (PDOException $e) {
    if ($db && $db->inTransaction()) {
        $db->rollBack();
    }
    http_response_code(400);
    $errorInfo = $e->errorInfo ?? [];
    $msg = $e->getMessage();
    
    if ($e->getCode() == 23505) {
        echo json_encode(["message" => "Error: El número de serie ya existe."]);
    } elseif ($e->getCode() == 23503) {
        echo json_encode(["message" => "Error de integridad: La marca o categoría seleccionada no es válida.", "details" => $msg]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Error de base de datos: " . $msg,
            "code" => $e->getCode(),
            "info" => $errorInfo
        ]);
    }
} catch (Exception $e) {
    if ($db && $db->inTransaction()) {
        $db->rollBack();
    }
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Error interno: " . $e->getMessage()
    ]);
}
?>
