<?php
// backend/api/workers/create.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->id) &&
    !empty($data->doc_type) &&
    !empty($data->name) &&
    !empty($data->lastName) &&
    !empty($data->position_id) &&
    !empty($data->startDate) &&
    !empty($data->phone) &&
    !empty($data->email) &&
    !empty($data->address) &&
    !empty($data->rh) &&
    !empty($data->sex)
) {
    try {
        // Check if worker exists
        $checkQuery = "SELECT id_trabajador FROM tab_trabajadores WHERE id_trabajador = :id";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->bindParam(':id', $data->id);
        $checkStmt->execute();

        if ($checkStmt->rowCount() > 0) {
            http_response_code(409); // Conflict
            echo json_encode(["message" => "El trabajador con este ID ya existe."]);
            exit;
        }

        $query = "INSERT INTO tab_trabajadores (
                    id_trabajador, tipo_documento, nom_trabajador, ape_trabajador,
                    id_cargo, fecha_ingreso_trabajador, tel_trabajador, correo_trabajador,
                    direccion_trabajador, rh_trabajador, sexo_trabajador
                ) VALUES (
                    :id, :doc_type, :name, :lastname, :position_id, :start_date,
                    :phone, :email, :address, :rh, :sex
                )";

        $stmt = $db->prepare($query);

        // Sanitize
        $data->id = htmlspecialchars(strip_tags($data->id));
        $data->doc_type = htmlspecialchars(strip_tags($data->doc_type));
        $data->name = htmlspecialchars(strip_tags($data->name));
        $data->lastName = htmlspecialchars(strip_tags($data->lastName));
        $data->position_id = htmlspecialchars(strip_tags($data->position_id));
        $data->startDate = htmlspecialchars(strip_tags($data->startDate));
        $data->phone = htmlspecialchars(strip_tags($data->phone));
        $data->email = htmlspecialchars(strip_tags($data->email));
        $data->address = htmlspecialchars(strip_tags($data->address));
        $data->rh = htmlspecialchars(strip_tags($data->rh));
        $data->sex = htmlspecialchars(strip_tags($data->sex));

        // Bind
        $stmt->bindParam(":id", $data->id);
        $stmt->bindParam(":doc_type", $data->doc_type);
        $stmt->bindParam(":name", $data->name);
        $stmt->bindParam(":lastname", $data->lastName);
        $stmt->bindParam(":position_id", $data->position_id);
        $stmt->bindParam(":start_date", $data->startDate);
        $stmt->bindParam(":phone", $data->phone);
        $stmt->bindParam(":email", $data->email);
        $stmt->bindParam(":address", $data->address);
        $stmt->bindParam(":rh", $data->rh);
        $stmt->bindParam(":sex", $data->sex);

        if (!$stmt->execute()) {
            throw new Exception("Error al ejecutar el query.");
        }

        // Si se enviaron ARL y EPS, insertar en tab_trabajadores_arl_eps
        if (!empty($data->arl_id) && !empty($data->eps_id)) {
            $idArl = (int)$data->arl_id;
            $idEps = (int)$data->eps_id;
            $qMax = $db->query("SELECT COALESCE(MAX(id_trabajador_arl_eps), 0) + 1 as n FROM tab_trabajadores_arl_eps");
            $nextId = (int)$qMax->fetch(PDO::FETCH_ASSOC)['n'];
            $ins = $db->prepare("INSERT INTO tab_trabajadores_arl_eps (id_trabajador_arl_eps, id_trabajador, id_arl, id_eps, fecha_afiliacion) VALUES (?, ?, ?, ?, ?)");
            $ins->execute([$nextId, $data->id, $idArl, $idEps, $data->startDate]);
        }

        http_response_code(201);
        echo json_encode(["message" => "Trabajador creado exitosamente."]);
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => "Error al crear trabajador: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos."]);
}
?>
