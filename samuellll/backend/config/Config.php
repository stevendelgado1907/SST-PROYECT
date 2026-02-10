<?php
// backend/config/Config.php

class Config {
    private static $env = [];
    private static $isLoaded = false;

    private static function load() {
        if (self::$isLoaded) return;

        // Intentar encontrar el archivo .env en la raíz (subiendo niveles desde backend/config/)
        $path = __DIR__ . '/../../.env';
        
        if (!file_exists($path)) {
            // Alternativa (fallback) o registro de errores
            return;
        }

        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (strpos(trim($line), '#') === 0) continue;
            
            list($name, $value) = explode('=', $line, 2);
            $name = trim($name);
            $value = trim($value);
            
            self::$env[$name] = $value;
        }
        self::$isLoaded = true;
    }

    public static function get($key, $default = null) {
        self::load();
        return isset(self::$env[$key]) ? self::$env[$key] : $default;
    }
}
?>
