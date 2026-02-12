-- CRUD para tab_arl
-- Archivo: database/functions/tab_arl/crud_tab_arl.sql

-- Función para Insertar ARL
CREATE OR REPLACE FUNCTION fn_tab_arl_insert(
    p_id_arl INTEGER,
    p_nom_arl VARCHAR(100),
    p_nit_arl VARCHAR(20),
    p_direccion_arl VARCHAR(200),
    p_tel_arl VARCHAR(15),
    p_correo_arl VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (id_arl INTEGER, nom_arl VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_arl IS NULL THEN RAISE EXCEPTION 'El ID de la ARL es obligatorio'; END IF;
    IF p_nom_arl IS NULL OR TRIM(p_nom_arl) = '' THEN RAISE EXCEPTION 'El nombre de la ARL es obligatorio'; END IF;
    IF p_nit_arl IS NULL OR TRIM(p_nit_arl) = '' THEN RAISE EXCEPTION 'El NIT de la ARL es obligatorio'; END IF;
    IF p_direccion_arl IS NULL OR TRIM(p_direccion_arl) = '' THEN RAISE EXCEPTION 'La dirección de la ARL es obligatoria'; END IF;
    IF p_tel_arl IS NULL OR TRIM(p_tel_arl) = '' THEN RAISE EXCEPTION 'El teléfono de la ARL es obligatorio'; END IF;

    -- Validaciones de Longitud
    IF LENGTH(p_nom_arl) > 100 THEN RAISE EXCEPTION 'El nombre excede los 100 caracteres'; END IF;
    IF LENGTH(p_nit_arl) > 20 THEN RAISE EXCEPTION 'El NIT excede los 20 caracteres'; END IF;
    IF LENGTH(p_direccion_arl) > 200 THEN RAISE EXCEPTION 'La dirección excede los 200 caracteres'; END IF;
    IF LENGTH(p_tel_arl) > 15 THEN RAISE EXCEPTION 'El teléfono excede los 15 caracteres'; END IF;
    IF p_correo_arl IS NOT NULL AND LENGTH(p_correo_arl) > 100 THEN RAISE EXCEPTION 'El correo excede los 100 caracteres'; END IF;

    -- Validación de formato de Correo (Básica)
    IF p_correo_arl IS NOT NULL AND p_correo_arl !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    -- Inserción
    RETURN QUERY
    INSERT INTO tab_arl (id_arl, nom_arl, nit_arl, direccion_arl, tel_arl, correo_arl)
    VALUES (p_id_arl, TRIM(p_nom_arl), TRIM(p_nit_arl), TRIM(p_direccion_arl), TRIM(p_tel_arl), LOWER(TRIM(p_correo_arl)))
    RETURNING tab_arl.id_arl, tab_arl.nom_arl;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe una ARL con ese ID, NIT o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar ARL: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar ARL
CREATE OR REPLACE FUNCTION fn_tab_arl_update(
    p_id_arl INTEGER,
    p_nom_arl VARCHAR(100),
    p_nit_arl VARCHAR(20),
    p_direccion_arl VARCHAR(200),
    p_tel_arl VARCHAR(15),
    p_correo_arl VARCHAR(100)
)
RETURNS TABLE (id_arl INTEGER, nom_arl VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_arl WHERE tab_arl.id_arl = p_id_arl) THEN
        RAISE EXCEPTION 'La ARL con ID % no existe', p_id_arl;
    END IF;

    -- Validaciones
    IF p_nom_arl IS NULL OR TRIM(p_nom_arl) = '' THEN RAISE EXCEPTION 'El nombre no puede estar vacío'; END IF;
    IF p_nit_arl IS NULL OR TRIM(p_nit_arl) = '' THEN RAISE EXCEPTION 'El NIT no puede estar vacío'; END IF;
    
    -- Validación de formato de Correo
    IF p_correo_arl IS NOT NULL AND p_correo_arl !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    -- Actualización
    RETURN QUERY
    UPDATE tab_arl
    SET nom_arl = TRIM(p_nom_arl),
        nit_arl = TRIM(p_nit_arl),
        direccion_arl = TRIM(p_direccion_arl),
        tel_arl = TRIM(p_tel_arl),
        correo_arl = LOWER(TRIM(p_correo_arl))
    WHERE tab_arl.id_arl = p_id_arl
    RETURNING tab_arl.id_arl, tab_arl.nom_arl;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otra ARL con ese NIT o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar ARL: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar ARL
CREATE OR REPLACE FUNCTION fn_tab_arl_delete(
    p_id_arl INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_arl WHERE id_arl = p_id_arl) THEN
        RAISE EXCEPTION 'La ARL con ID % no existe', p_id_arl;
    END IF;

    -- Verificación de dependencias (tab_trabajadores_arl_eps, tab_trabajadores_arl_ips)
    IF EXISTS (SELECT 1 FROM tab_trabajadores_arl_eps WHERE id_arl = p_id_arl) OR
       EXISTS (SELECT 1 FROM tab_trabajadores_arl_ips WHERE id_arl = p_id_arl) THEN
        RAISE EXCEPTION 'No se puede eliminar la ARL porque tiene trabajadores afiliados asociados';
    END IF;

    DELETE FROM tab_arl WHERE id_arl = p_id_arl;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
