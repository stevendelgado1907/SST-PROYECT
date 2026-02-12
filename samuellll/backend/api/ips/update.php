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

$required = ['name', 'address', 'phone'];
foreach ($required as $f) {
    if (empty($data->$f)) {
        http_response_code(400);
        echo json_encode(["message" => "Datos incompletos."]);
        exit;
    }
}

try {
    // Validaciones backend coherentes con BD
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

    // Verificar si el nombre ya existe para otra IPS
    $checkName = $db->prepare("SELECT id_ips FROM tab_ips WHERE nom_ips = :name AND id_ips != :id");
    $checkName->bindParam(":name", $data->name);
    $checkName->bindParam(":id", $data->id);
    $checkName->execute();
    if ($checkName->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(["message" => "El nombre de IPS ya está registrado para otra entidad."]);
        exit;
    }

    $q = "UPDATE tab_ips SET nom_ips = :name, direccion_ips = :address, tel_ips = :phone, correo_ips = :email WHERE id_ips = :id";
    $stmt = $db->prepare($q);
    
    $id = (int)$data->id;
    $name = htmlspecialchars(strip_tags($data->name));
    $address = htmlspecialchars(strip_tags($data->address));
    $phone = htmlspecialchars(strip_tags($data->phone));
    $email = !empty($data->email) ? htmlspecialchars(strip_tags($data->email)) : null;

    $stmt->bindParam(":id", $id);
    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":address", $address);
    $stmt->bindParam(":phone", $phone);
    $stmt->bindParam(":email", $email);

    if ($stmt->execute()) {
        echo json_encode(["message" => "IPS actualizada exitosamente."]);
    } else {
        throw new Exception("Error al actualizar.");
    }
} catch (PDOException $e) {
    if ($e->getCode() == 23505) {
        http_response_code(400);
        echo json_encode(["message" => "El nombre de IPS ya existe."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => $e->getMessage()]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
