CREATE OR REPLACE FUNCTION fn_validar_usuario_login(
    p_correo VARCHAR
) 
RETURNS TABLE (
    id_usuario INTEGER,
    correo_usuario VARCHAR,
    pass_hash VARCHAR,
    nombre_rol VARCHAR
) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        u.id_usuario,
        u.correo_usuario,
        u.pass_hash,
        r.nombre_rol
    FROM 
        tab_usuarios u
    JOIN 
        tab_roles r ON u.id_rol = r.id_rol
    WHERE 
        u.correo_usuario = p_correo
        AND u.estado_usuario = 'ACTIVO';
END;
$$ LANGUAGE plpgsql;
