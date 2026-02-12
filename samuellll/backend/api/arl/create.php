<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

$required = ['name', 'nit', 'address', 'phone'];
foreach ($required as $f) {
    if (empty($data->$f)) {
        http_response_code(400);
        echo json_encode(["message" => "Datos incompletos. Campo requerido: " . $f]);
        exit;
    }
}

try {
    $qMax = "SELECT COALESCE(MAX(id_arl), 0) + 1 as next_id FROM tab_arl";
    $st = $db->query($qMax);
    $nextId = $st->fetch(PDO::FETCH_ASSOC)['next_id'];

    // Validaciones backend coherentes con BD
    // Validar NIT (BD: VARCHAR(20) UNIQUE) - formato: números y guiones opcionales
    if (!preg_match('/^[\d-]+$/', $data->nit) || strlen($data->nit) > 20) {
        http_response_code(400);
        echo json_encode(["message" => "NIT inválido. Debe contener solo números y guiones (máximo 20 caracteres)."]);
        exit;
    }

    // Validar teléfono (BD: VARCHAR(15))
    if (!preg_match('/^\d+$/', $data->phone) || strlen($data->phone) > 15 || strlen($data->phone) < 7) {
        http_response_code(400);
        echo json_encode(["message" => "Teléfono inválido. Debe contener solo números (7-15 dígitos)."]);
        exit;
    }

    // Validar email si se proporciona (BD: VARCHAR(100))
    if (!empty($data->email)) {
        if (!filter_var($data->email, FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(["message" => "Correo electrónico inválido."]);
            exit;
        }
        if (strlen($data->email) > 100) {
            http_response_code(400);
            echo json_encode(["message" => "El correo no puede exceder 100 caracteres."]);
            exit;
        }
    }

    // Validar longitudes según BD
    if (strlen($data->name) > 100) {
        http_response_code(400);
        echo json_encode(["message" => "El nombre no puede exceder 100 caracteres."]);
        exit;
    }
    if (strlen($data->address) > 200) {
        http_response_code(400);
        echo json_encode(["message" => "La dirección no puede exceder 200 caracteres."]);
        exit;
    }

    $q = "INSERT INTO tab_arl (id_arl, nom_arl, nit_arl, direccion_arl, tel_arl, correo_arl) 
          VALUES (:id, :name, :nit, :address, :phone, :email)";
    $stmt = $db->prepare($q);
    
    $name = htmlspecialchars(strip_tags($data->name));
    $nit = htmlspecialchars(strip_tags($data->nit));
    $address = htmlspecialchars(strip_tags($data->address));
    $phone = htmlspecialchars(strip_tags($data->phone));
    $email = !empty($data->email) ? htmlspecialchars(strip_tags($data->email)) : null;

    $stmt->bindParam(":id", $nextId);
    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":nit", $nit);
    $stmt->bindParam(":address", $address);
    $stmt->bindParam(":phone", $phone);
    $stmt->bindParam(":email", $email);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode(["message" => "ARL creada exitosamente.", "id" => (int)$nextId]);
    } else {
        throw new Exception("Error al insertar.");
    }
} catch (PDOException $e) {
    if ($e->getCode() == 23505) {
        http_response_code(400);
        echo json_encode(["message" => "El NIT ya existe."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => $e->getMessage()]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
