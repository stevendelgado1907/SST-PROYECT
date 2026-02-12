-- CRUD para tab_categorias
-- Archivo: database/functions/tab_categorias/crud_tab_categorias.sql

-- Función para Insertar Categoría
CREATE OR REPLACE FUNCTION fn_tab_categorias_insert(
    p_id_categoria INTEGER,
    p_nom_categoria VARCHAR(100),
    p_descripcion_categoria VARCHAR(255)
)
RETURNS TABLE (id_categoria INTEGER, nom_categoria VARCHAR) AS $$
BEGIN
    -- Validaciones
    IF p_id_categoria IS NULL THEN RAISE EXCEPTION 'El ID de la categoría es obligatorio'; END IF;
    IF p_nom_categoria IS NULL OR TRIM(p_nom_categoria) = '' THEN RAISE EXCEPTION 'El nombre de la categoría es obligatorio'; END IF;

    -- Inserción
    RETURN QUERY
    INSERT INTO tab_categorias (id_categoria, nom_categoria, descripcion_categoria)
    VALUES (p_id_categoria, TRIM(p_nom_categoria), TRIM(p_descripcion_categoria))
    RETURNING tab_categorias.id_categoria, tab_categorias.nom_categoria;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe una categoría con ese ID o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar categoría: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Categoría
CREATE OR REPLACE FUNCTION fn_tab_categorias_update(
    p_id_categoria INTEGER,
    p_nom_categoria VARCHAR(100),
    p_descripcion_categoria VARCHAR(255)
)
RETURNS TABLE (id_categoria INTEGER, nom_categoria VARCHAR) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_categorias WHERE tab_categorias.id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'La categoría con ID % no existe', p_id_categoria;
    END IF;

    -- Actualización
    RETURN QUERY
    UPDATE tab_categorias
    SET nom_categoria = TRIM(p_nom_categoria),
        descripcion_categoria = TRIM(p_descripcion_categoria)
    WHERE tab_categorias.id_categoria = p_id_categoria
    RETURNING tab_categorias.id_categoria, tab_categorias.nom_categoria;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otra categoría con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar categoría: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Categoría
CREATE OR REPLACE FUNCTION fn_tab_categorias_delete(
    p_id_categoria INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_categorias WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'La categoría con ID % no existe', p_id_categoria;
    END IF;

    -- Dependencias
    IF EXISTS (SELECT 1 FROM tab_epp WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'No se puede eliminar la categoría porque tiene EPPs asociados';
    END IF;

    DELETE FROM tab_categorias WHERE id_categoria = p_id_categoria;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
