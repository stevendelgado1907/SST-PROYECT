-- CRUD para tab_trabajadores
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_trabajadores.sql

-- Función para Insertar Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trabajadores_insert(
    p_id_trabajador VARCHAR(20),
    p_tipo_documento VARCHAR(3),
    p_id_cargo INTEGER,
    p_nom_trabajador VARCHAR(100),
    p_ape_trabajador VARCHAR(100),
    p_tel_trabajador VARCHAR(15),
    p_correo_trabajador VARCHAR(100),
    p_direccion_trabajador VARCHAR(200),
    p_rh_trabajador VARCHAR(5),
    p_sexo_trabajador VARCHAR(10),
    p_fecha_ingreso_trabajador DATE
)
RETURNS TABLE (id_trabajador VARCHAR, nom_trabajador VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_trabajador IS NULL OR TRIM(p_id_trabajador) = '' THEN RAISE EXCEPTION 'El documento es obligatorio'; END IF;
    IF p_nom_trabajador IS NULL OR TRIM(p_nom_trabajador) = '' THEN RAISE EXCEPTION 'El nombre es obligatorio'; END IF;
    IF p_id_cargo IS NULL THEN RAISE EXCEPTION 'El cargo es obligatorio'; END IF;

    -- Validaciones de Longitud
    IF LENGTH(p_id_trabajador) > 20 THEN RAISE EXCEPTION 'El documento excede los 20 caracteres'; END IF;
    IF LENGTH(p_nom_trabajador) > 100 THEN RAISE EXCEPTION 'El nombre excede los 100 caracteres'; END IF;
    IF p_correo_trabajador IS NOT NULL AND p_correo_trabajador !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    -- Verificación de Cargo
    IF NOT EXISTS (SELECT 1 FROM tab_cargos WHERE id_cargo = p_id_cargo) THEN
        RAISE EXCEPTION 'El cargo especificado no existe';
    END IF;

    RETURN QUERY
    INSERT INTO tab_trabajadores (id_trabajador, tipo_documento, id_cargo, nom_trabajador, ape_trabajador, tel_trabajador, correo_trabajador, direccion_trabajador, rh_trabajador, sexo_trabajador, fecha_ingreso_trabajador)
    VALUES (TRIM(p_id_trabajador), p_tipo_documento, p_id_cargo, TRIM(p_nom_trabajador), TRIM(p_ape_trabajador), TRIM(p_tel_trabajador), LOWER(TRIM(p_correo_trabajador)), TRIM(p_direccion_trabajador), p_rh_trabajador, p_sexo_trabajador, p_fecha_ingreso_trabajador)
    RETURNING tab_trabajadores.id_trabajador, tab_trabajadores.nom_trabajador;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un trabajador con ese ID o Correo.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar trabajador: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trabajadores_update(
    p_id_trabajador VARCHAR(20),
    p_id_cargo INTEGER,
    p_nom_trabajador VARCHAR(100),
    p_ape_trabajador VARCHAR(100),
    p_tel_trabajador VARCHAR(15),
    p_correo_trabajador VARCHAR(100),
    p_direccion_trabajador VARCHAR(200),
    p_rh_trabajador VARCHAR(5),
    p_sexo_trabajador VARCHAR(10),
    p_fecha_retiro_trabajador DATE DEFAULT NULL
)
RETURNS TABLE (id_trabajador VARCHAR, nom_trabajador VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'El trabajador con ID % no existe', p_id_trabajador;
    END IF;

    -- Validaciones
    IF p_nom_trabajador IS NULL OR TRIM(p_nom_trabajador) = '' THEN RAISE EXCEPTION 'El nombre no puede estar vacío'; END IF;
    IF p_correo_trabajador IS NOT NULL AND p_correo_trabajador !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    -- Verificación de Cargo
    IF NOT EXISTS (SELECT 1 FROM tab_cargos WHERE id_cargo = p_id_cargo) THEN
        RAISE EXCEPTION 'El cargo especificado no existe';
    END IF;

    RETURN QUERY
    UPDATE tab_trabajadores
    SET id_cargo = p_id_cargo,
        nom_trabajador = TRIM(p_nom_trabajador),
        ape_trabajador = TRIM(p_ape_trabajador),
        tel_trabajador = TRIM(p_tel_trabajador),
        correo_trabajador = LOWER(TRIM(p_correo_trabajador)),
        direccion_trabajador = TRIM(p_direccion_trabajador),
        rh_trabajador = p_rh_trabajador,
        sexo_trabajador = p_sexo_trabajador,
        fecha_retiro_trabajador = p_fecha_retiro_trabajador
    WHERE tab_trabajadores.id_trabajador = p_id_trabajador
    RETURNING tab_trabajadores.id_trabajador, tab_trabajadores.nom_trabajador;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro trabajador con ese correo.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar trabajador: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Trabajador
CREATE OR REPLACE FUNCTION fn_tab_trabajadores_delete(p_id_trabajador VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'El trabajador con ID % no existe', p_id_trabajador;
    END IF;

    -- Verificación de dependencias críticas antes de eliminar
    IF EXISTS (SELECT 1 FROM tab_trabajadores_epp WHERE id_trabajador = p_id_trabajador) THEN
        RAISE EXCEPTION 'No se puede eliminar el trabajador tiene EPPs asignados';
    END IF;

    DELETE FROM tab_trabajadores WHERE id_trabajador = p_id_trabajador;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar el trabajador porque tiene registros vinculados en otras tablas';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar trabajador: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Trabajadores
CREATE OR REPLACE FUNCTION fn_tab_trabajadores_select(p_id_trabajador VARCHAR(20) DEFAULT NULL)
RETURNS TABLE (
    id_trabajador VARCHAR(20),
    tipo_documento VARCHAR(3),
    id_cargo INTEGER,
    nom_cargo VARCHAR(100),
    nom_trabajador VARCHAR(100),
    ape_trabajador VARCHAR(100),
    tel_trabajador VARCHAR(15),
    correo_trabajador VARCHAR(100),
    direccion_trabajador VARCHAR(200),
    rh_trabajador VARCHAR(5),
    sexo_trabajador VARCHAR(10),
    fecha_ingreso_trabajador DATE,
    fecha_retiro_trabajador DATE,
    fecha_registro TIMESTAMP
) AS $$
BEGIN
    IF p_id_trabajador IS NULL THEN
        RETURN QUERY 
        SELECT t.id_trabajador, t.tipo_documento, t.id_cargo, c.nom_cargo, t.nom_trabajador, t.ape_trabajador, t.tel_trabajador, t.correo_trabajador, t.direccion_trabajador, t.rh_trabajador, t.sexo_trabajador, t.fecha_ingreso_trabajador, t.fecha_retiro_trabajador, t.fecha_registro 
        FROM tab_trabajadores t
        JOIN tab_cargos c ON t.id_cargo = c.id_cargo;
    ELSE
        RETURN QUERY 
        SELECT t.id_trabajador, t.tipo_documento, t.id_cargo, c.nom_cargo, t.nom_trabajador, t.ape_trabajador, t.tel_trabajador, t.correo_trabajador, t.direccion_trabajador, t.rh_trabajador, t.sexo_trabajador, t.fecha_ingreso_trabajador, t.fecha_retiro_trabajador, t.fecha_registro 
        FROM tab_trabajadores t 
        JOIN tab_cargos c ON t.id_cargo = c.id_cargo
        WHERE t.id_trabajador = p_id_trabajador;
    END IF;
END;
$$ LANGUAGE plpgsql;
