-- CRUD para tab_roles
-- Archivo: database/functions/tab_roles/crud_tab_roles.sql

-- Función para Insertar Rol
CREATE OR REPLACE FUNCTION fn_tab_roles_insert(
    p_id_rol INTEGER,
    p_nombre_rol VARCHAR(50)
)
RETURNS TABLE (id_rol INTEGER, nombre_rol VARCHAR) AS $$
BEGIN
    -- Validaciones
    IF p_id_rol IS NULL THEN
        RAISE EXCEPTION 'El ID del rol no puede ser nulo';
    END IF;

    IF p_nombre_rol IS NULL OR TRIM(p_nombre_rol) = '' THEN
        RAISE EXCEPTION 'El nombre del rol no puede estar vacío';
    END IF;

    IF LENGTH(p_nombre_rol) > 50 THEN
        RAISE EXCEPTION 'El nombre del rol no puede exceder los 50 caracteres';
    END IF;

    -- Inserción
    RETURN QUERY
    INSERT INTO tab_roles (id_rol, nombre_rol)
    VALUES (p_id_rol, TRIM(p_nombre_rol))
    RETURNING tab_roles.id_rol, tab_roles.nombre_rol;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: El ID o el nombre del rol ya existen.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error inesperado al insertar rol: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Rol
CREATE OR REPLACE FUNCTION fn_tab_roles_update(
    p_id_rol INTEGER,
    p_nombre_rol VARCHAR(50)
)
RETURNS TABLE (id_rol INTEGER, nombre_rol VARCHAR) AS $$
BEGIN
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM tab_roles WHERE tab_roles.id_rol = p_id_rol) THEN
        RAISE EXCEPTION 'El rol con ID % no existe', p_id_rol;
    END IF;

    IF p_nombre_rol IS NULL OR TRIM(p_nombre_rol) = '' THEN
        RAISE EXCEPTION 'El nombre del rol no puede estar vacío';
    END IF;

    IF LENGTH(p_nombre_rol) > 50 THEN
        RAISE EXCEPTION 'El nombre del rol no puede exceder los 50 caracteres';
    END IF;

    -- Actualización
    RETURN QUERY
    UPDATE tab_roles
    SET nombre_rol = TRIM(p_nombre_rol)
    WHERE tab_roles.id_rol = p_id_rol
    RETURNING tab_roles.id_rol, tab_roles.nombre_rol;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro rol con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error inesperado al actualizar rol: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Rol
CREATE OR REPLACE FUNCTION fn_tab_roles_delete(
    p_id_rol INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM tab_roles WHERE id_rol = p_id_rol) THEN
        RAISE EXCEPTION 'El rol con ID % no existe', p_id_rol;
    END IF;

    -- Verificación de integridad referencial (tab_usuarios depende de tab_roles)
    IF EXISTS (SELECT 1 FROM tab_usuarios WHERE id_rol = p_id_rol) THEN
        RAISE EXCEPTION 'No se puede eliminar el rol porque tiene usuarios asociados';
    END IF;

    DELETE FROM tab_roles WHERE id_rol = p_id_rol;
    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar rol: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
