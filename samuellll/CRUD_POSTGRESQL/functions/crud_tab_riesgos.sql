-- CRUD para tab_riesgos
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_riesgos.sql

-- Función para Insertar Riesgo
CREATE OR REPLACE FUNCTION fn_tab_riesgos_insert(
    p_id_riesgo INTEGER,
    p_nom_riesgo VARCHAR(100),
    p_tipo_riesgo VARCHAR(100),
    p_descripcion_riesgo TEXT,
    p_nivel_de_riesgo VARCHAR(50),
    p_probabilidad_riesgo VARCHAR(50),
    p_severidad_riesgo VARCHAR(50),
    p_medidas_control VARCHAR(255)
)
RETURNS TABLE (id_riesgo INTEGER, nom_riesgo VARCHAR) AS $$
BEGIN
    -- Validaciones
    IF p_id_riesgo IS NULL THEN RAISE EXCEPTION 'El ID del riesgo es obligatorio'; END IF;
    IF p_nom_riesgo IS NULL OR TRIM(p_nom_riesgo) = '' THEN RAISE EXCEPTION 'El nombre del riesgo es obligatorio'; END IF;

    RETURN QUERY
    INSERT INTO tab_riesgos (id_riesgo, nom_riesgo, tipo_riesgo, descripcion_riesgo, nivel_de_riesgo, probabilidad_riesgo, severidad_riesgo, medidas_control)
    VALUES (p_id_riesgo, TRIM(p_nom_riesgo), TRIM(p_tipo_riesgo), TRIM(p_descripcion_riesgo), p_nivel_de_riesgo, p_probabilidad_riesgo, p_severidad_riesgo, TRIM(p_medidas_control))
    RETURNING tab_riesgos.id_riesgo, tab_riesgos.nom_riesgo;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un riesgo con ese ID o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Riesgo
CREATE OR REPLACE FUNCTION fn_tab_riesgos_update(
    p_id_riesgo INTEGER,
    p_nom_riesgo VARCHAR(100),
    p_tipo_riesgo VARCHAR(100),
    p_descripcion_riesgo TEXT,
    p_nivel_de_riesgo VARCHAR(50),
    p_probabilidad_riesgo VARCHAR(50),
    p_severidad_riesgo VARCHAR(50),
    p_medidas_control VARCHAR(255)
)
RETURNS TABLE (id_riesgo INTEGER, nom_riesgo VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_riesgos WHERE id_riesgo = p_id_riesgo) THEN
        RAISE EXCEPTION 'El riesgo con ID % no existe', p_id_riesgo;
    END IF;

    RETURN QUERY
    UPDATE tab_riesgos
    SET nom_riesgo = TRIM(p_nom_riesgo),
        tipo_riesgo = TRIM(p_tipo_riesgo),
        descripcion_riesgo = TRIM(p_descripcion_riesgo),
        nivel_de_riesgo = p_nivel_de_riesgo,
        probabilidad_riesgo = p_probabilidad_riesgo,
        severidad_riesgo = p_severidad_riesgo,
        medidas_control = TRIM(p_medidas_control)
    WHERE tab_riesgos.id_riesgo = p_id_riesgo
    RETURNING tab_riesgos.id_riesgo, tab_riesgos.nom_riesgo;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro riesgo con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Riesgo
CREATE OR REPLACE FUNCTION fn_tab_riesgos_delete(p_id_riesgo INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_riesgos WHERE id_riesgo = p_id_riesgo) THEN
        RAISE EXCEPTION 'El riesgo con ID % no existe', p_id_riesgo;
    END IF;

    DELETE FROM tab_riesgos WHERE id_riesgo = p_id_riesgo;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar el riesgo porque tiene trabajadores asociados';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar riesgo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Riesgos
CREATE OR REPLACE FUNCTION fn_tab_riesgos_select(p_id_riesgo INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_riesgo INTEGER,
    nom_riesgo VARCHAR(100),
    tipo_riesgo VARCHAR(100),
    descripcion_riesgo TEXT,
    nivel_de_riesgo VARCHAR(50),
    probabilidad_riesgo VARCHAR(50),
    severidad_riesgo VARCHAR(50),
    medidas_control VARCHAR(255)
) AS $$
BEGIN
    IF p_id_riesgo IS NULL THEN
        RETURN QUERY 
        SELECT r.id_riesgo, r.nom_riesgo, r.tipo_riesgo, r.descripcion_riesgo, r.nivel_de_riesgo, r.probabilidad_riesgo, r.severidad_riesgo, r.medidas_control 
        FROM tab_riesgos r;
    ELSE
        RETURN QUERY 
        SELECT r.id_riesgo, r.nom_riesgo, r.tipo_riesgo, r.descripcion_riesgo, r.nivel_de_riesgo, r.probabilidad_riesgo, r.severidad_riesgo, r.medidas_control 
        FROM tab_riesgos r 
        WHERE r.id_riesgo = p_id_riesgo;
    END IF;
END;
$$ LANGUAGE plpgsql;
