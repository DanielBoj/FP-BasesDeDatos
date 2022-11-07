-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: FP.046_PRODUCTO2
--
-- Grupo: Cnv0922_Grupo03: Nínive
-- 
-- Integrantes: 
-- 1. Katiane Coutinho Rosa
-- 2. Miki Alvarez Vidal
-- 3. Daniel Zafra del Pino
-- 4. Daniel Boj Cobos
--
-- Database: ICX0_P3_3
-- --------------------------------------------------------------

USE ICX0_P3_3;

-- Consultas Externas

--
-- Pregunta 1
--

START TRANSACTION;

SELECT s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS 'Apellido', (
		SELECT p.plan
		FROM plan p 
		WHERE p.id_plan = s.id_plan) AS 'Nombre del Plan'
	FROM socio s 
    JOIN corporativo c 
    ON (c.id_socio = s.id_socio)
    LEFT JOIN inscripcion i
    ON (i.id_socio = s.id_socio)
    WHERE (s.id_socio NOT IN (
		SELECT id_socio
        FROM inscripcion))
    ORDER BY s.id_socio;

COMMIT;

--
-- Pregunta 2
--

START TRANSACTION;

SELECT s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS 'Apellido', (
		SELECT p.plan
		FROM plan p 
		WHERE p.id_plan = s.id_plan) AS 'Nombre del Plan'
	FROM socio s 
    LEFT JOIN historico h
    ON (h.id_socio = s.id_socio)
    WHERE (s.id_socio NOT IN (
		SELECT id_socio
        FROM historico))
    ORDER BY id_plan, fecha_alta;
    
COMMIT;

--
-- Pregunta 3
--

START TRANSACTION;

SELECT sc.id_socio AS 'ID Socio', sc.nombre AS 'Nombre', sc.apellido1 AS 'Apellido', (DATEDIFF(CURDATE(), sc.fecha_alta)) AS 'Días de Alta en el Gimnasio'
	FROM socio sc 
    LEFT JOIN seguimiento sg
    ON (sg.id_socio = sc.id_socio)
    WHERE (sc.id_socio NOT IN (
		SELECT id_socio
        FROM corporativo))
	AND (sc.id_socio NOT IN (
		SELECT id_socio
        FROM seguimiento))
	ORDER BY (
		SELECT IF (s.id_socio IN (b.id_socio), 'Beneficiario', 'Principal') AS 'Tipo'
		FROM socio s
		LEFT JOIN beneficiario b
		ON (b.id_socio = s.id_socio)
        WHERE (s.id_socio = sc.id_socio));
        
COMMIT;

-- Subconsultas