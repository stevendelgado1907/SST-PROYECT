CREATE OR REPLACE FUNCTION fn_insertar_rol(
    p_nombre_rol VARCHAR(50)
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validaciones
    IF p_nombre_rol IS NULL OR TRIM(p_nombre_rol) = '' THEN
        RAISE EXCEPTION 'El nombre del rol no puede estar vacío';
    END IF;
    
    IF LENGTH(p_nombre_rol) > 50 THEN
        RAISE EXCEPTION 'El nombre del rol no puede exceder 50 caracteres';
    END IF;
    
    -- Inserción
    INSERT INTO tab_roles (id_rol, nombre_rol)
    VALUES (NEXTVAL('seq_roles'), UPPER(TRIM(p_nombre_rol)))
    RETURNING id_rol INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un rol con este nombre';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar rol: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;