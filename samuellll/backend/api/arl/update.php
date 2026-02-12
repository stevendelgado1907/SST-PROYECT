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

if (empty($data->id)) {
    http_response_code(400);
    echo json_encode(["message" => "ID requerido."]);
    exit;
}

$required = ['name', 'nit', 'address', 'phone'];
foreach ($required as $f) {
    if (empty($data->$f)) {
        http_response_code(400);
        echo json_encode(["message" => "Datos incompletos."]);
        exit;
    }
}

try {
    // Validaciones backend coherentes con BD
    // Validar NIT (BD: VARCHAR(20) UNIQUE)
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

    // Verificar si el NIT ya existe para otra ARL
    $checkNit = $db->prepare("SELECT id_arl FROM tab_arl WHERE nit_arl = :nit AND id_arl != :id");
    $checkNit->bindParam(":nit", $data->nit);
    $checkNit->bindParam(":id", $data->id);
    $checkNit->execute();
    if ($checkNit->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(["message" => "El NIT ya está registrado para otra ARL."]);
        exit;
    }

    $q = "UPDATE tab_arl SET nom_arl = :name, nit_arl = :nit, direccion_arl = :address, 
          tel_arl = :phone, correo_arl = :email WHERE id_arl = :id";
    $stmt = $db->prepare($q);
    
    $id = (int)$data->id;
    $name = htmlspecialchars(strip_tags($data->name));
    $nit = htmlspecialchars(strip_tags($data->nit));
    $address = htmlspecialchars(strip_tags($data->address));
    $phone = htmlspecialchars(strip_tags($data->phone));
    $email = !empty($data->email) ? htmlspecialchars(strip_tags($data->email)) : null;

    $stmt->bindParam(":id", $id);
    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":nit", $nit);
    $stmt->bindParam(":address", $address);
    $stmt->bindParam(":phone", $phone);
    $stmt->bindParam(":email", $email);

    if ($stmt->execute()) {
        echo json_encode(["message" => "ARL actualizada exitosamente."]);
    } else {
        throw new Exception("Error al actualizar.");
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
