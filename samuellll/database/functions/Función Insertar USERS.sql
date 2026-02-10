CREATE OR REPLACE FUNCTION fn_insertar_usuario(
    p_correo_usuario VARCHAR(150),
    p_pass_hash VARCHAR(255),
    p_id_rol INTEGER,
    p_estado_usuario VARCHAR(50) DEFAULT 'Activo'
) RETURNS INTEGER AS $$
DECLARE
    v_id_insertado INTEGER;
BEGIN
    -- Validaciones
    IF p_correo_usuario IS NULL OR TRIM(p_correo_usuario) = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio';
    END IF;
    
    IF POSITION('@' IN p_correo_usuario) = 0 THEN
        RAISE EXCEPTION 'El correo electrónico debe contener @';
    END IF;
    
    IF LENGTH(p_correo_usuario) > 150 THEN
        RAISE EXCEPTION 'El correo no puede exceder 150 caracteres';
    END IF;
    
    IF p_pass_hash IS NULL OR LENGTH(p_pass_hash) < 8 THEN
        RAISE EXCEPTION 'La contraseña debe tener al menos 8 caracteres';
    END IF;
    
    IF p_id_rol IS NULL THEN
        RAISE EXCEPTION 'El ID del rol es obligatorio';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM tab_roles WHERE id_rol = p_id_rol) THEN
        RAISE EXCEPTION 'El rol con ID % no existe', p_id_rol;
    END IF;
    
    -- Inserción
    INSERT INTO tab_usuarios (
        id_usuario, 
        correo_usuario, 
        pass_hash, 
        id_rol, 
        estado_usuario
    )
    VALUES (
        NEXTVAL('seq_usuarios'),
        LOWER(TRIM(p_correo_usuario)),
        p_pass_hash,
        p_id_rol,
        UPPER(TRIM(p_estado_usuario))
    )
    RETURNING id_usuario INTO v_id_insertado;
    
    RETURN v_id_insertado;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un usuario con este correo electrónico';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar usuario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;