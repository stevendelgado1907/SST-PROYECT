-- CRUD para inventario_epp
-- Archivo: CRUD_POSTGRESQL/functions/crud_inventario_epp.sql

-- Función para Insertar/Inicializar Inventario
CREATE OR REPLACE FUNCTION fn_inventario_epp_insert(
    p_id_inventario INTEGER,
    p_id_epp INTEGER,
    p_stock_actual INTEGER,
    p_stock_minimo INTEGER DEFAULT 10,
    p_stock_maximo INTEGER DEFAULT 100,
    p_punto_reorden INTEGER DEFAULT 20
)
RETURNS TABLE (id_inv INTEGER) AS $$
BEGIN
    -- Validaciones
    IF p_id_inventario IS NULL THEN RAISE EXCEPTION 'El ID de inventario es obligatorio'; END IF;
    IF p_id_epp IS NULL THEN RAISE EXCEPTION 'El ID del EPP es obligatorio'; END IF;
    IF p_stock_actual < 0 THEN RAISE EXCEPTION 'El stock no puede ser negativo'; END IF;

    -- Verificar existencia de EPP
    IF NOT EXISTS (SELECT 1 FROM tab_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'El EPP especificado no existe';
    END IF;

    RETURN QUERY
    INSERT INTO inventario_epp (id_inventario, id_epp, stock_actual, stock_minimo, stock_maximo, punto_reorden)
    VALUES (p_id_inventario, p_id_epp, p_stock_actual, p_stock_minimo, p_stock_maximo, p_punto_reorden)
    RETURNING inventario_epp.id_inventario;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un registro de inventario para este ID o EPP.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al inicializar inventario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Stock
CREATE OR REPLACE FUNCTION fn_inventario_epp_update(
    p_id_epp INTEGER,
    p_nuevo_stock INTEGER
)
RETURNS TABLE (id_inv INTEGER, epp_id INTEGER) AS $$
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM inventario_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'No existe registro de inventario para el EPP con ID %', p_id_epp;
    END IF;

    IF p_nuevo_stock < 0 THEN RAISE EXCEPTION 'El stock no puede ser negativo'; END IF;

    RETURN QUERY
    UPDATE inventario_epp
    SET stock_actual = p_nuevo_stock,
        ultima_actualizacion = CURRENT_TIMESTAMP
    WHERE id_epp = p_id_epp
    RETURNING inventario_epp.id_inventario, inventario_epp.id_epp;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar inventario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar del Inventario
CREATE OR REPLACE FUNCTION fn_inventario_epp_delete(p_id_epp INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM inventario_epp WHERE id_epp = p_id_epp) THEN
        RAISE EXCEPTION 'No existe registro de inventario para el EPP con ID %', p_id_epp;
    END IF;

    DELETE FROM inventario_epp WHERE id_epp = p_id_epp;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar del inventario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Ver Inventario
CREATE OR REPLACE FUNCTION fn_inventario_epp_select(p_id_epp INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_inventario INTEGER,
    id_epp INTEGER,
    nom_epp VARCHAR(100),
    referencia_epp VARCHAR(100),
    nom_marca VARCHAR(100),
    nom_categoria VARCHAR(100),
    stock_actual INTEGER,
    stock_minimo INTEGER,
    stock_maximo INTEGER,
    punto_reorden INTEGER,
    ultima_actualizacion TIMESTAMP
) AS $$
BEGIN
    IF p_id_epp IS NULL THEN
        RETURN QUERY 
        SELECT i.id_inventario, i.id_epp, e.nom_epp, e.referencia_epp, m.nom_marca, c.nom_categoria, i.stock_actual, i.stock_minimo, i.stock_maximo, i.punto_reorden, i.ultima_actualizacion 
        FROM inventario_epp i
        JOIN tab_epp e ON i.id_epp = e.id_epp
        LEFT JOIN tab_marcas m ON e.id_marca = m.id_marca
        LEFT JOIN tab_categorias c ON e.id_categoria = c.id_categoria;
    ELSE
        RETURN QUERY 
        SELECT i.id_inventario, i.id_epp, e.nom_epp, e.referencia_epp, m.nom_marca, c.nom_categoria, i.stock_actual, i.stock_minimo, i.stock_maximo, i.punto_reorden, i.ultima_actualizacion 
        FROM inventario_epp i 
        JOIN tab_epp e ON i.id_epp = e.id_epp
        LEFT JOIN tab_marcas m ON e.id_marca = m.id_marca
        LEFT JOIN tab_categorias c ON e.id_categoria = c.id_categoria
        WHERE i.id_epp = p_id_epp;
    END IF;
END;
$$ LANGUAGE plpgsql;
