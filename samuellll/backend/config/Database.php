<?php
// backend/config/Database.php
require_once __DIR__ . '/Config.php';

class Database {
    private $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $host = Config::get('DB_HOST');
            $db_name = Config::get('DB_NAME');
            $username = Config::get('DB_USER');
            $password = Config::get('DB_PASSWORD');
            $port = Config::get('DB_PORT');

            $dsn = "pgsql:host=" . $host . ";port=" . $port . ";dbname=" . $db_name;

            $this->conn = new PDO($dsn, $username, $password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        } catch(PDOException $exception) {
            error_log("Connection error: " . $exception->getMessage());
            header("Content-Type: application/json; charset=UTF-8");
            http_response_code(500);
            echo json_encode(["message" => "Error de conexión a la base de datos.", "details" => $exception->getMessage()]);
            exit;
        }

        return $this->conn;
    }
}
?>
