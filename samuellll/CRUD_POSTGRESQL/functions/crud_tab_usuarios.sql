-- CRUD para tab_usuarios
-- Archivo: CRUD_POSTGRESQL/functions/crud_tab_usuarios.sql

-- Función para Insertar Usuario
CREATE OR REPLACE FUNCTION fn_tab_usuarios_insert(
    p_id_usuario INTEGER,
    p_correo_usuario VARCHAR(150),
    p_pass_hash VARCHAR(255),
    p_id_rol INTEGER,
    p_nombre_usuario VARCHAR(100),
    p_apellido_usuario VARCHAR(100)
)
RETURNS TABLE (id_usuario INTEGER, correo_usuario VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_usuario IS NULL THEN RAISE EXCEPTION 'El ID es obligatorio'; END IF;
    IF p_correo_usuario IS NULL OR TRIM(p_correo_usuario) = '' THEN RAISE EXCEPTION 'El correo es obligatorio'; END IF;
    IF p_pass_hash IS NULL OR TRIM(p_pass_hash) = '' THEN RAISE EXCEPTION 'La contraseña es obligatoria'; END IF;
    IF p_id_rol IS NULL THEN RAISE EXCEPTION 'El rol es obligatorio'; END IF;

    -- Validaciones de Longitud
    IF LENGTH(p_correo_usuario) > 150 THEN RAISE EXCEPTION 'El correo excede los 150 caracteres'; END IF;
    IF LENGTH(p_nombre_usuario) > 100 THEN RAISE EXCEPTION 'El nombre excede los 100 caracteres'; END IF;
    IF LENGTH(p_apellido_usuario) > 100 THEN RAISE EXCEPTION 'El apellido excede los 100 caracteres'; END IF;

    -- Validación de Formato de Correo
    IF p_correo_usuario !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    -- Verificación de Rol
    IF NOT EXISTS (SELECT 1 FROM tab_roles WHERE id_rol = p_id_rol) THEN
        RAISE EXCEPTION 'El rol especificado no existe';
    END IF;

    RETURN QUERY
    INSERT INTO tab_usuarios (id_usuario, correo_usuario, pass_hash, id_rol, nombre_usuario, apellido_usuario)
    VALUES (p_id_usuario, LOWER(TRIM(p_correo_usuario)), p_pass_hash, p_id_rol, TRIM(p_nombre_usuario), TRIM(p_apellido_usuario))
    RETURNING tab_usuarios.id_usuario, tab_usuarios.correo_usuario;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un usuario con ese ID o Correo.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar usuario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Usuario
CREATE OR REPLACE FUNCTION fn_tab_usuarios_update(
    p_id_usuario INTEGER,
    p_correo_usuario VARCHAR(150),
    p_id_rol INTEGER,
    p_estado_usuario VARCHAR(50),
    p_nombre_usuario VARCHAR(100),
    p_apellido_usuario VARCHAR(100)
)
RETURNS TABLE (id_usuario INTEGER, correo_usuario VARCHAR) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'El usuario con ID % no existe', p_id_usuario;
    END IF;

    -- Validaciones básicas
    IF p_correo_usuario IS NULL OR TRIM(p_correo_usuario) = '' THEN RAISE EXCEPTION 'El correo no puede estar vacío'; END IF;
    
    IF p_correo_usuario !~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'El formato del correo es inválido';
    END IF;

    -- Verificación de Rol
    IF NOT EXISTS (SELECT 1 FROM tab_roles WHERE id_rol = p_id_rol) THEN
        RAISE EXCEPTION 'El rol especificado no existe';
    END IF;

    RETURN QUERY
    UPDATE tab_usuarios
    SET correo_usuario = LOWER(TRIM(p_correo_usuario)),
        id_rol = p_id_rol,
        estado_usuario = TRIM(p_estado_usuario),
        nombre_usuario = TRIM(p_nombre_usuario),
        apellido_usuario = TRIM(p_apellido_usuario)
    WHERE tab_usuarios.id_usuario = p_id_usuario
    RETURNING tab_usuarios.id_usuario, tab_usuarios.correo_usuario;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro usuario con ese correo.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar usuario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Usuario
CREATE OR REPLACE FUNCTION fn_tab_usuarios_delete(p_id_usuario INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'El usuario con ID % no existe', p_id_usuario;
    END IF;

    -- PostgreSQL manejará las dependencias si hay llaves foráneas con restricciones restrictivas
    DELETE FROM tab_usuarios WHERE id_usuario = p_id_usuario;
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar el usuario porque tiene registros asociados en el sistema';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar usuario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar/Consultar Usuarios
CREATE OR REPLACE FUNCTION fn_tab_usuarios_select(p_id_usuario INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_usuario INTEGER,
    correo_usuario VARCHAR(150),
    pass_hash VARCHAR(255),
    id_rol INTEGER,
    nombre_rol VARCHAR(50),
    fecha_creacion TIMESTAMP,
    ultimo_acceso TIMESTAMP,
    estado_usuario VARCHAR(50),
    nombre_usuario VARCHAR(100),
    apellido_usuario VARCHAR(100)
) AS $$
BEGIN
    IF p_id_usuario IS NULL THEN
        RETURN QUERY 
        SELECT u.id_usuario, u.correo_usuario, u.pass_hash, u.id_rol, r.nombre_rol, u.fecha_creacion, u.ultimo_acceso, u.estado_usuario, u.nombre_usuario, u.apellido_usuario 
        FROM tab_usuarios u
        JOIN tab_roles r ON u.id_rol = r.id_rol;
    ELSE
        RETURN QUERY 
        SELECT u.id_usuario, u.correo_usuario, u.pass_hash, u.id_rol, r.nombre_rol, u.fecha_creacion, u.ultimo_acceso, u.estado_usuario, u.nombre_usuario, u.apellido_usuario 
        FROM tab_usuarios u 
        JOIN tab_roles r ON u.id_rol = r.id_rol
        WHERE u.id_usuario = p_id_usuario;
    END IF;
END;
$$ LANGUAGE plpgsql;
