-- INDEXES --
-------------
CREATE INDEX IDX_REGION
ON CLIENTES(region);

CREATE INDEX IDX_CLI_REGION
ON CLIENTES(region, id_cliente);

-- INFORME 1 --
---------------
-- Crear view
CREATE OR REPLACE VIEW VW_RESUMEN_CLIENTES AS
SELECT 
    c.region AS "REGION",
    COUNT(
        CASE 
          WHEN (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_inscripcion)) >= 20 
          THEN 1 
        END
    ) AS "CLI_20_ANIOS",
-- Total clientes
    COUNT(*) AS "TOTAL_CLIENTES"
FROM CLIENTES c
GROUP BY c.region;

SELECT
    "REGION",
    "CLI_20_ANIOS",
    "TOTAL_CLIENTES"
FROM VW_RESUMEN_CLIENTES
ORDER BY "CLI_20_ANIOS" ASC;

-- INFORME 2 -- CON OPERADORES SET --
-------------------------------------
-- Aquí se utiliza un operador SET para combinar los resultados de dos conjuntos, sirve bastante para dividir el rango de los meses en dos subconjuntos y luego unir los resultados.

SELECT 
    TO_CHAR(SYSDATE, 'DD-MM-YYYY') AS "FECHA_EMISION",
    TTT.descripcion AS "DESCRIPCION_TRANSACCION",
    ROUND(AVG(TR.valor_transaccion), 2) AS "PROMEDIO_MONTO"
FROM TIPO_TRANSACCION_TARJETA TTT
     INNER JOIN TRANSACCIONES TR ON TTT.id_tipo_transaccion = TR.id_tipo_transaccion
WHERE EXTRACT(MONTH FROM TR.fecha_limite) BETWEEN 6 AND 8
GROUP BY TTT.descripcion

UNION

SELECT 
    TO_CHAR(SYSDATE, 'DD-MM-YYYY') AS "FECHA_EMISION",
    TTT.descripcion AS "DESCRIPCION_TRANSACCION",
    ROUND(AVG(TR.valor_transaccion), 2) AS "PROMEDIO_MONTO"
FROM TIPO_TRANSACCION_TARJETA TTT
     INNER JOIN TRANSACCIONES TR ON TTT.id_tipo_transaccion = TR.id_tipo_transaccion
WHERE EXTRACT(MONTH FROM TR.fecha_limite) BETWEEN 9 AND 12
GROUP BY TTT.descripcion
ORDER BY 3 ASC;

-- INFORME 2 -- USANDO SUBCONSULTA --
-------------------------------------
-- Aquí se crea una tabla para almacenar los resultados de transacciones del 2do semestre.

CREATE TABLE SELECCION_TIPO_TRANSACCION (
    id_tipo_transaccion    NUMBER,
    descripcion            VARCHAR2(200),
    promedio_monto         NUMBER(18,2),
    fecha_emision          VARCHAR2(10)
);

-- Poblar la tabla con los resultados del segundo semestre

INSERT INTO SELECCION_TIPO_TRANSACCION (id_tipo_transaccion, descripcion, promedio_monto, fecha_emision)
SELECT
    TTT.id_tipo_transaccion,
    TTT.descripcion,
    ROUND(AVG(TR.valor_transaccion), 2) AS PROMEDIO_MONTO,
    TO_CHAR(SYSDATE, 'DD-MM-YYYY')      AS FECHA_EMISION
FROM TIPO_TRANSACCION_TARJETA TTT
     INNER JOIN TRANSACCIONES TR ON TTT.id_tipo_transaccion = TR.id_tipo_transaccion
WHERE EXTRACT(MONTH FROM TR.fecha_limite) BETWEEN 6 AND 12
GROUP BY TTT.id_tipo_transaccion, TTT.descripcion;

-- Verificar los datos
SELECT *
FROM SELECCION_TIPO_TRANSACCION
ORDER BY promedio_monto ASC;

-- Actualizar tasa de interés

UPDATE TIPO_TRANSACCION_TARJETA T
SET T.porcentaje_interes = T.porcentaje_interes - 0.01
WHERE T.id_tipo_transaccion IN (
    SELECT S.id_tipo_transaccion
    FROM SELECCION_TIPO_TRANSACCION S
);

-- RESPUESTAS A PREGUNTAS INFORME 2 --
-- 1) ¿Cuál es el problema que se debe resolver?
El problema a resolver es generar un informe con transacciones cuyas cuotas vencen en el 2do semetre, mostrando promedio de montos y actualizar las tasas de interés basado en los resultados.

-- 2) ¿Cuál es la información significativa que necesita?
Se necesita la relación entre TRANSACCIONES y TIPO_TRANSACCION_TARJETA, fechas de vencimiento y montos.

-- 3) ¿Cuál es el propósito de la solución?
Se podrían obtener informes por cada tipo de transacción e ir aplicando actualizaciones a cada uno.

-- 4) y 5) Los comentarios describen cada paso en lenguaje natural para cada alternativa.
