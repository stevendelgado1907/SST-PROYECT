-- =====================================================
-- INTEGRACIÓN MATRIZ DE RIESGOS - PROTEGO (PostgreSQL)
-- =====================================================

-- 1. Tablas de catálogo para la Matriz
-- =====================================================

CREATE TABLE IF NOT EXISTS areas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    responsable VARCHAR(100),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_areas_nombre ON areas(nombre);

CREATE TABLE IF NOT EXISTS procesos (
    id SERIAL PRIMARY KEY,
    area_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_procesos_area ON procesos(area_id);

CREATE TABLE IF NOT EXISTS tipos_riesgo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    descripcion TEXT,
    color VARCHAR(7) DEFAULT '#6c757d',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_tipos_riesgo_codigo ON tipos_riesgo(codigo);

-- 2. Tabla Principal: Matriz de Riesgos
-- =====================================================

CREATE TABLE IF NOT EXISTS matriz_riesgos (
    id SERIAL PRIMARY KEY,
    area_id INT NOT NULL,
    proceso_id INT,
    tipo_riesgo_id INT NOT NULL,
    peligro TEXT NOT NULL,
    descripcion TEXT,
    
    -- Probabilidad (escala 1-5)
    probabilidad INT NOT NULL CHECK (probabilidad BETWEEN 1 AND 5),
    
    -- Impacto/Severidad (escala 1-5)
    impacto INT NOT NULL CHECK (impacto BETWEEN 1 AND 5),
    
    -- Nivel de riesgo calculado (probabilidad * impacto)
    -- Postgres 12+ supports generated columns. We use a simple column and trigger if needed, 
    -- but generated is better if supported. fallback to simple column if issues arise.
    nivel_riesgo INT GENERATED ALWAYS AS (probabilidad * impacto) STORED,
    
    -- Categorización automática
    categoria_riesgo VARCHAR(20) GENERATED ALWAYS AS (
        CASE 
            WHEN (probabilidad * impacto) <= 5 THEN 'BAJO'
            WHEN (probabilidad * impacto) <= 12 THEN 'MEDIO'
            WHEN (probabilidad * impacto) <= 20 THEN 'ALTO'
            ELSE 'EXTREMO'
        END
    ) STORED,
    
    -- Exposición
    frecuencia_exposicion VARCHAR(20) NOT NULL CHECK (frecuencia_exposicion IN ('Esporádica', 'Ocasional', 'Frecuente', 'Continua')),
    numero_trabajadores_expuestos INT NOT NULL DEFAULT 1,
    
    -- Controles existentes
    controles_actuales TEXT,
    
    -- Medidas de control propuestas
    eliminacion TEXT,
    sustitucion TEXT,
    controles_ingenieria TEXT,
    controles_administrativos TEXT,
    equipos_proteccion TEXT,
    
    -- Estado y seguimiento
    estado VARCHAR(20) DEFAULT 'Identificado' CHECK (estado IN ('Identificado', 'En evaluación', 'Controlado', 'Cerrado')),
    
    prioridad INT GENERATED ALWAYS AS (
        CASE 
            WHEN (probabilidad * impacto) > 20 THEN 1 -- EXTREMO
            WHEN (probabilidad * impacto) > 12 THEN 2 -- ALTO
            WHEN (probabilidad * impacto) > 5 THEN 3  -- MEDIO
            ELSE 4 -- BAJO
        END
    ) STORED,
    
    -- Responsable y fechas
    responsable VARCHAR(100),
    fecha_identificacion DATE NOT NULL,
    fecha_evaluacion DATE,
    fecha_control DATE,
    fecha_verificacion DATE,
    
    -- Observaciones
    observaciones TEXT,
    
    -- Metadata
    creado_por INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modificado_por INT,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE CASCADE,
    FOREIGN KEY (proceso_id) REFERENCES procesos(id) ON DELETE SET NULL,
    FOREIGN KEY (tipo_riesgo_id) REFERENCES tipos_riesgo(id) ON DELETE RESTRICT,
    FOREIGN KEY (creado_por) REFERENCES tab_usuarios(id_usuario) ON DELETE SET NULL,
    FOREIGN KEY (modificado_por) REFERENCES tab_usuarios(id_usuario) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_matriz_categoria ON matriz_riesgos(categoria_riesgo);
CREATE INDEX IF NOT EXISTS idx_matriz_nivel ON matriz_riesgos(nivel_riesgo);
CREATE INDEX IF NOT EXISTS idx_matriz_estado ON matriz_riesgos(estado);

-- 3. Historial y Auditoría
-- =====================================================

CREATE TABLE IF NOT EXISTS historial_cambios (
    id SERIAL PRIMARY KEY,
    riesgo_id INT NOT NULL,
    usuario_id INT,
    accion VARCHAR(20) NOT NULL CHECK (accion IN ('Creación', 'Modificación', 'Cambio de estado', 'Eliminación')),
    campo_modificado VARCHAR(100),
    valor_anterior TEXT,
    valor_nuevo TEXT,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    
    FOREIGN KEY (riesgo_id) REFERENCES matriz_riesgos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES tab_usuarios(id_usuario) ON DELETE SET NULL
);

-- 4. Inserción de Datos Iniciales (Catálogos)
-- =====================================================

INSERT INTO areas (nombre, descripcion) VALUES
('Producción', 'Área de manufactura'),
('Mantenimiento', 'Mantenimiento general'),
('Logística', 'Almacén y distribución'),
('Administración', 'Oficinas'),
('Calidad', 'Control de calidad')
ON CONFLICT DO NOTHING;

INSERT INTO procesos (area_id, nombre) VALUES
(1, 'Ensamblaje'), (1, 'Soldadura'),
(2, 'Eléctrico'), (2, 'Mecánico'),
(3, 'Carga/Descarga'), (3, 'Almacenamiento')
ON CONFLICT DO NOTHING;

INSERT INTO tipos_riesgo (nombre, codigo, color) VALUES
('Riesgo Biológico', 'BIO', '#8b4513'),
('Riesgo Físico', 'FIS', '#4169e1'),
('Riesgo Químico', 'QUI', '#ff6347'),
('Riesgo Psicosocial', 'PSI', '#9370db'),
('Riesgo Biomecánico', 'BIM', '#20b2aa'),
('Riesgo Eléctrico', 'ELE', '#ffa500'),
('Riesgo Mecánico', 'MEC', '#dc143c'),
('Riesgo Locativo', 'LOC', '#32cd32'),
('Riesgo de Incendio', 'INC', '#ff4500'),
('Riesgo Natural', 'NAT', '#8fbc8f'),
('Riesgo Tecnológico', 'TEC', '#4682b4'),
('Riesgo de Tránsito', 'TRA', '#696969'),
('Riesgo Público', 'PUB', '#cd5c5c')
ON CONFLICT (codigo) DO NOTHING;
