<?php
// backend/api/workers/update.php
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
    !empty($data->name) &&
    !empty($data->lastName) &&
    !empty($data->position_id) &&
    !empty($data->phone) &&
    !empty($data->email) &&
    !empty($data->address) &&
    !empty($data->rh) &&
    !empty($data->sex)
) {
    try {
        $query = "UPDATE tab_trabajadores SET
                    nom_trabajador = :name,
                    ape_trabajador = :lastname,
                    id_cargo = :position_id,
                    fecha_ingreso_trabajador = :start_date,
                    tel_trabajador = :phone,
                    correo_trabajador = :email,
                    direccion_trabajador = :address,
                    rh_trabajador = :rh,
                    sexo_trabajador = :sex
                WHERE id_trabajador = :id";

        $stmt = $db->prepare($query);

        // Sanitize
        $data->id = htmlspecialchars(strip_tags($data->id));
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
            throw new Exception("Error al actualizar el trabajador.");
        }

        // Actualizar ARL/EPS
        $db->prepare("UPDATE tab_trabajadores_arl_eps SET fecha_retiro = CURRENT_DATE WHERE id_trabajador = ? AND fecha_retiro IS NULL")->execute([$data->id]);
        $idArl = !empty($data->arl_id) ? (int)$data->arl_id : null;
        $idEps = !empty($data->eps_id) ? (int)$data->eps_id : null;
        if ($idArl && $idEps) {
            $qMax = $db->query("SELECT COALESCE(MAX(id_trabajador_arl_eps), 0) + 1 as n FROM tab_trabajadores_arl_eps");
            $nextId = (int)$qMax->fetch(PDO::FETCH_ASSOC)['n'];
            $ins = $db->prepare("INSERT INTO tab_trabajadores_arl_eps (id_trabajador_arl_eps, id_trabajador, id_arl, id_eps, fecha_afiliacion) VALUES (?, ?, ?, ?, ?)");
            $ins->execute([$nextId, $data->id, $idArl, $idEps, $data->startDate ?? date('Y-m-d')]);
        }

        http_response_code(200);
        echo json_encode(["message" => "Trabajador actualizado exitosamente."]);
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => "Error al actualizar: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos."]);
}
?>
