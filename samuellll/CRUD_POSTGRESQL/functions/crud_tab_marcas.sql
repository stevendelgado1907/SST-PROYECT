-- CRUD para tab_marcas
-- Archivo: database/functions/tab_marcas/crud_tab_marcas.sql

-- Función para Insertar Marca
CREATE OR REPLACE FUNCTION fn_tab_marcas_insert(
    p_id_marca INTEGER,
    p_nom_marca VARCHAR(100),
    p_proveedor_marca VARCHAR(100),
    p_contacto_proveedor VARCHAR(15)
)
RETURNS TABLE (id_marca INTEGER, nom_marca VARCHAR) AS $$
BEGIN
    -- Validaciones
    IF p_id_marca IS NULL THEN RAISE EXCEPTION 'El ID de la marca es obligatorio'; END IF;
    IF p_nom_marca IS NULL OR TRIM(p_nom_marca) = '' THEN RAISE EXCEPTION 'El nombre de la marca es obligatorio'; END IF;

    -- Inserción
    RETURN QUERY
    INSERT INTO tab_marcas (id_marca, nom_marca, proveedor_marca, contacto_proveedor)
    VALUES (p_id_marca, TRIM(p_nom_marca), TRIM(p_proveedor_marca), TRIM(p_contacto_proveedor))
    RETURNING tab_marcas.id_marca, tab_marcas.nom_marca;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe una marca con ese ID o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar marca: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Marca
CREATE OR REPLACE FUNCTION fn_tab_marcas_update(
    p_id_marca INTEGER,
    p_nom_marca VARCHAR(100),
    p_proveedor_marca VARCHAR(100),
    p_contacto_proveedor VARCHAR(15)
)
RETURNS TABLE (id_marca INTEGER, nom_marca VARCHAR) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_marcas WHERE tab_marcas.id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca con ID % no existe', p_id_marca;
    END IF;

    -- Actualización
    RETURN QUERY
    UPDATE tab_marcas
    SET nom_marca = TRIM(p_nom_marca),
        proveedor_marca = TRIM(p_proveedor_marca),
        contacto_proveedor = TRIM(p_contacto_proveedor)
    WHERE tab_marcas.id_marca = p_id_marca
    RETURNING tab_marcas.id_marca, tab_marcas.nom_marca;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otra marca con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar marca: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Marca
CREATE OR REPLACE FUNCTION fn_tab_marcas_delete(
    p_id_marca INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_marcas WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca con ID % no existe', p_id_marca;
    END IF;

    -- Dependencias
    IF EXISTS (SELECT 1 FROM tab_epp WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'No se puede eliminar la marca porque tiene EPPs asociados';
    END IF;

    DELETE FROM tab_marcas WHERE id_marca = p_id_marca;
    RETURN TRUE;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'No se puede eliminar la marca porque tiene EPPs u otros registros asociados';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar marca: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Listar Marcas
CREATE OR REPLACE FUNCTION fn_tab_marcas_select(p_id_marca INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_marca INTEGER,
    nom_marca VARCHAR(100),
    proveedor_marca VARCHAR(100),
    contacto_proveedor VARCHAR(15)
) AS $$
BEGIN
    IF p_id_marca IS NULL THEN
        RETURN QUERY 
        SELECT m.id_marca, m.nom_marca, m.proveedor_marca, m.contacto_proveedor 
        FROM tab_marcas m;
    ELSE
        RETURN QUERY 
        SELECT m.id_marca, m.nom_marca, m.proveedor_marca, m.contacto_proveedor 
        FROM tab_marcas m 
        WHERE m.id_marca = p_id_marca;
    END IF;
END;
$$ LANGUAGE plpgsql;
