USE icx0_p3_3;

--
-- Ejercicio 1. Crear manualmente una tabla denominada birthdays.
--

DROP TABLE IF EXISTS birthdays;

CREATE TABLE IF NOT EXISTS birthdays (
	id_birthday INT UNSIGNED NOT NULL AUTO_INCREMENT,
    para VARCHAR(200),
    asunto VARCHAR(200),
    texto VARCHAR(600),
    PRIMARY KEY (id_birthday)
);

/* Creamos la tabla mediante una sentencia CREATE, se le añade una PK id_birthday de tipo autoincrementa. Como no hay relaciones conocidas con otras tablas, no se generar FK.
*/

--
-- Ejercicio 2. Crear un procedimiento almacenado que realice lo siguiente:
 
				/*Eliminar de la tabla birthdays  los registros anteriores.
				Revisar la tabla de socios e insertar una felicitación de cumpleaños en la tabla birthdays para aquellos socios que cumplen años el día siguiente. En el campo para: insertar el mail del socio. En asunto escribir: Estimado o estimada (según el sexo) + nombre del socio + “. Feliz cumpleaños!”. En texto escribir: Estimado o estimada (según el sexo) + nombre del socio + “Sabemos que mañana es un día especial y por eso te invitamos a celebrar. Tienes un descuento del 30% en nuestro restaurante FIT al mostrar este e-mail. Esperamos que lo disfrutes, Gymcenter.”.  Tanto el asunto como el texto de la felicitación deberá tomar en cuenta el sexo del socio.*/
--

DROP PROCEDURE IF EXISTS p_generar_felicitaciones_cumpleanios;

DELIMITER |

CREATE PROCEDURE p_generar_felicitaciones_cumpleanios()
MODIFIES SQL DATA
SQL SECURITY DEFINER
BEGIN
	DECLARE done INT DEFAULT 0;
    DECLARE act_nombre, act_apellido1, act_apellido2, act_email VARCHAR(45);
    DECLARE act_sexo CHAR;
    DECLARE act_fecha_nacimiento DATE;
    
    DECLARE act_socio CURSOR FOR
		SELECT nombre, apellido1, apellido2, sexo, fecha_nacimiento, email
        FROM socio;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    DELETE FROM birthdays
		WHERE id_birthday > 0;
	ALTER TABLE birthdays
		AUTO_INCREMENT = 1;
    
    START TRANSACTION;
    
    OPEN act_socio;
    WHILE done = 0 DO
		FETCH act_socio 
			INTO act_nombre, act_apellido1, act_apellido2, act_sexo,
			act_fecha_nacimiento, act_email;
			
		IF MONTH(act_fecha_nacimiento) = MONT(DATE_ADD(CURDATE(), INTERVAL 1 DAY)) AND
			DAY(act_fecha_nacimiento) = DAY(DATE_ADD(CURDATE(), INTERVAL 1 DAY))
			THEN INSERT INTO birthdays
				(para, asunto, texto) VALUES (
                act_email,
                CONCAT(IF(act_sexo = 'M', 'Estimada ', 'Estimado '), act_nombre, '. Feliz cumpleaños!'),
                CONCAT(IF(act_sexo = 'M', 'Estimada ', 'Estimado '), act_nombre, '. Sabemos que mañana es un día especial y
                por eso te invitamos a celebrar. Tienes un descuento del 30% en nuestro restaurante FIT al mostrar este e-mail. Esperamos que 
                lo disfrutes, Gymcenter.')
                );
		END IF;
	END WHILE;
	CLOSE act_socio;
    
    COMMIT;
END|

DELIMITER ;

/* Para generar un procedimiento, usamos la sentencia CREATE PROCEDURE nombre_proceso(); esto será igual para todos los procesos generados en esta actividad.
1. Eliminamos todos los registros de la tabla, si existieran, mediante una sentencia DELETE, para que no salte el aviso de seguridad, usamos el PK en la cláusula WHERE.
2. Como estamos usando una PK autogenerado, debemos resetearla para volver a empezar de nuevo al regenerar la tabla, usamos la sentencia ALTER TABLE.
3. Iniciamos la lectura registro a registro mediante un cursor, generamos un bucle WHILE para iterar fila a fila mientras haya reistros disponibles.
4. Usamos FETCH para cargar los datos en las variables locales los valores recuperados de cada fila de la tabla. El orden debe respetar el de la sentencia SELECT en la declaración del cursor.
5. Mediante una sentencia IF, comprobamos si el mes y el día de la fecha de nacimiento, usando MONTH y DAY respectivamente sobre las fechas, coincide con la fecha para el día siguiente al actual, para ello, añadimos 1 día a la fecha actual con DATE_ADD().
6. Si es así, realizamos la inserción en la tabla birthdays, comprobamos el sexo mediante la función IF y concatenamos el valor correcto.
*/
 
--
-- Ejericio 3. Crear un evento que ejecute cada día el procedimiento anterior a las 8 de la mañana.
--

SET GLOBAL event_scheduler= ON;

SET @next_day = CONCAT(ADDDATE(CURDATE(), INTERVAL 1 DAY), ' ' , '08:00');

DROP EVENT IF EXISTS comprobar_cumpleanios;

CREATE EVENT IF NOT EXISTS comprobar_cumpleanios
	ON SCHEDULE EVERY 1 DAY
		STARTS @next_day
    DO CALL generar_felicitaciones_cumpleanios();
/* Primero activamos el event scheduler por si estuviera desactivado en la tabla.
1. Usamos una variable para crear el datetiume de inicio de evento de forma dinámica, así se adaptará al día en que se ejecute el script. Usamos un ADDDATE para escoger el día siguiente al actual y concatenamos la hora de inicio.
2. Para crear un evento, usamos una sentencia CREATE EVENT, esto será igual para todos los eventos generados en este Producto.
3. Ejecutaremos el evento de forma repetida cada día a las 8AM, así que usamos la cláusua ON SCHEDULE EVERY y 1 DAY para indicar que se repita cada día. PAra seleccionar correctamente la hora de comienzo, usamos la cláusula START seguida del DATETIME que hemos generado previamente.
4. Selecciamos el proceso que queremos ejecutar mediante la cláusla DO CALL.
*/

--
-- Ejercicio 4. Crear manualmente una tabla denominada domiciliaciones. Agregar los siguientes campos: idSocioPrincipal, mes, año,  cuentaDomiciliación, Banco, importe.
--

DROP TABLE IF EXISTS domiciliaciones;

CREATE TABLE IF NOT EXISTS domiciliaciones (
	id_domiciliacion INT UNSIGNED NOT NULL UNIQUE AUTO_INCREMENT,
    id_socio_principal INT NOT NULL UNIQUE,
    mes INT NOT NULL,
    anio INT NOT NULL,
    cuenta_domiciliacion VARCHAR(20) NOT NULL UNIQUE,
    banco VARCHAR(200) NOT NULL,
    importe DECIMAL(10,2),
    PRIMARY KEY (id_domiciliacion)
);

ALTER TABLE domiciliaciones
	ADD CONSTRAINT fk_socio_principal FOREIGN KEY (id_socio_principal)
    REFERENCES principal (idsocio)
    ON UPDATE CASCADE ON DELETE CASCADE;
/* Creamos la tabla mediante la sentencia CREATE TABLE, aunque no se indique, creamos un PK autogenerada id_domicialiacion.
Podemos entender que el campo id_socio_principal será una FK que relacione las tablas domiciliaciones y proncipal, donde constan las identificaciones y números de cuenta de todos los socios principales del gimnasio.

--
-- Ejercicio 5. Crear un procedimiento almacenado que realice lo siguiente:
 
				/* Vaciar la tabla domiciliaciones
				Generar las domiciliaciones del mes a los socios no corporativos que se encuentren activos. Para ello se deberá sumar a la cuota de su mensualidad, las inscripciones a actividades extras y las cuotas de sus beneficiarios.
				*/
--

-- Funciones auxiliares

DROP FUNCTION IF EXISTS f_cuota_total;

DELIMITER |

CREATE FUNCTION f_cuota_total (id_socio_buscado INT) 
RETURNS decimal(10,2)
READS SQL DATA
BEGIN
	DECLARE total decimal(10,2);
    DECLARE extra decimal(10,2);
	SET total = (SELECT
		CASE
			WHEN id_socio_buscado IN (SELECT b.id_socio FROM beneficiario b) THEN ROUND(((100 - b.porcentaje_descuento) / 100 ) * p.cuota_mensual, 2)
			WHEN id_socio_buscado IN (SELECT p.idsocio FROM principal p) THEN p.cuota_mensual
			WHEN id_socio_buscado IN (SELECT c.id_socio FROM corporativo c) THEN p.cuota_mensual
        END
		FROM socio s
		INNER JOIN plan p
			ON p.id_plan = s.id_plan
		LEFT JOIN beneficiario b
			ON id_socio_buscado = b.id_socio
		LEFT JOIN corporativo c
			ON id_socio_buscado = c.id_socio
		WHERE id_socio_buscado = s.id_socio);
        
    SET extra = (SELECT
		CASE
			WHEN id_socio_buscado IN (SELECT id_socio FROM inscripcion) THEN (SELECT
				CASE
					WHEN i.id_socio IN (SELECT idsocio FROM principal) 
						THEN ROUND(mensualidad - ((e.descuento_abonados / 100) * mensualidad), 2)
					ELSE e.mensualidad
                    END
                    FROM inscripcion i 
					JOIN extra e
						ON i.id_actividad = e.id_actividad
					WHERE id_socio_buscado = i.id_socio AND i.fecha_baja IS NULL
			)
			ELSE 0
		END
	);
            
    SET total = total + extra;
    
    IF total IS NULL AND f_encontrar_tipo_socio(id_socio_buscado) = 'Principal'
		THEN SET total = (SELECT p.cuota_mensual
							FROM socio s
                            INNER JOIN plan p
								ON p.id_plan = s.id_plan
                            WHERE s.id_socio = id_socio_buscado
		);
	END IF;
    
	RETURN total;
END |

DELIMITER ;

DROP FUNCTION IF EXISTS f_encontrar_tipo_socio;

DELIMITER |

CREATE FUNCTION f_encontrar_tipo_socio(inId_socio INT)
	RETURNS VARCHAR(20)
	READS SQL DATA	
    SQL SECURITY DEFINER
    BEGIN
		DECLARE act_tipo VARCHAR(20);
		SELECT CASE
		WHEN s.id_socio = c.id_socio THEN 'Corporativo'
		WHEN s.id_socio = p.idsocio THEN 'Principal'
		WHEN s.id_socio = b.id_socio THEN 'Beneficiario'
		END AS 'Tipo de Socio'
	FROM socio s
		LEFT JOIN corporativo c
			ON (c.id_socio = s.id_socio)
		LEFT JOIN principal p
			ON (p.idsocio = s.id_socio)
		LEFT JOIN beneficiario b
			ON (b.id_socio = s.id_socio)
	WHERE s.id_socio = inId_socio
	INTO act_tipo;
    RETURN act_tipo;    
    END |

DELIMITER ;

DROP PROCEDURE IF EXISTS p_cobro_cuotas_socios;

DELIMITER |

CREATE PROCEDURE p_cobro_cuotas_socios()
MODIFIES SQL DATA
SQL SECURITY DEFINER
BEGIN
	DECLARE done INT default 0;
    DECLARE act_id_socio INT;
    DECLARE act_activo TINYINT;
    DECLARE act_cuota DECIMAL(10,2);
    DECLARE act_tipo, act_cuenta, act_banco VARCHAR(60);
	
    DECLARE act_socio CURSOR FOR
		SELECT DISTINCT p.idsocio, s.activo, p.cuenta, p.banco
			FROM principal p
            INNER JOIN socio s
				ON s.id_socio = p.idsocio;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
        
	DELETE FROM domiciliaciones
		WHERE id_domiciliacion > 0;
	ALTER TABLE domiciliaciones
		AUTO_INCREMENT = 1;
        
	START TRANSACTION;
    
    OPEN act_socio;
    loop_lectura: LOOP
		FETCH act_socio 
			INTO act_id_socio, act_activo, act_cuenta, act_banco;
		IF done = 1
		THEN leave loop_lectura;
		END IF;
        
		SET act_tipo = f_encontrar_tipo_socio(act_id_socio);
		SET act_cuota = f_cuota_total(act_id_socio);
		
        IF act_tipo = 'Principal' AND act_activo = 1
			THEN
            INSERT INTO domiciliaciones
            (id_socio_principal, mes, anio, cuenta_domiciliacion, banco, importe) VALUES
            (act_id_socio, MONTH(CURDATE()), YEAR(CURDATE()), act_cuenta, act_banco, act_cuota);
		END IF;
    END LOOP;
    
    CLOSE act_socio;
END |

DELIMITER ;

/* Para facilitar la codificación de este proceso usamos dos funciones auxiliares:
1 - f_cuota_total: Actualiza la funcióon creada en productos anteriores para el calculo de la cuto de un socio incluyendo el precio de las posibles actividades extra a las que esté apuntado el socio.
2 - f_encontrar_tipo_socio: Devuelve el tipo de socio para saber si se trata de un socio principal y poder discriminar las filas que usaremos en el proceso principal.
Creamos el proceso p_cobro_cuotas_socios():
1. Usaremos un cursor que obtenga los datos del socio de la tabla socio y princial. Necesitamos la tabla socio para saber si está activo.
2. Limpiamos la tabla domiciliaciones mediante una sentencia DELETE, hay que usar la PK en la cláusula WHERE para evitar errores de seguridad y acordarnos de reiniciar el contador autogenerado de la PK.
3. Abrimos el cursor e iniciamos la lectura fila a fila, en este caso, controlamos la iteración mediante una sentencia LOOP, para probar otro método.
4. Mediante FECTCH cargamos los datos del registro en las variables locales.
5. Usamos las funciones auxiliares para encontrar el tipo de socio y la cutoa mensual total de este.
6. Con una sentencia IF, controlamos que el socio sea de tipo Principal y, de ser así, isertamos los datos en la tabla domiciliaciones.
*/

--
-- Ejercicio 6. Crear un evento que se ejecute el día 1 de cada mes para exportar la tabla domiciliaciones generada por el procedimiento anterior a un archivo de texto.
--
SET @siguiente_dia_1 = ADDDATE(ADDDATE(CURDATE(), INTERVAL 1 MONTH), - DAY(CURDATE()) + 1);

DROP EVENT IF EXISTS generar_domiciliaciones;

CREATE EVENT IF NOT EXISTS generar_domiciliaciones
	ON SCHEDULE EVERY 1 MONTH 
		STARTS @siguiente_dia_1
    DO CALL cobro_cuotas_socios();
/* Creamos una variable para asignar el DATETIME en el que iniciaremos el proceso. Debemos buscar el siguiente primero de mes, así que añadimos un mes a la fecha actual con ADDDATE y le restamos los días actuales de mes + 1.
1. Creamos el evento y lo programamos para repetirse mensualmente mediante la cláusula ON SCHEDUE EVERY, usamos como intervalo 1 MONTH para que se repita cada mes.
2. Controlamos que el proceso se inicie el día 1 del próximo mes mediante la cláusula START y la variable que hemos creado.
3. Asignamos el proceso a ejecutar mediante las cláusular DO y CALL.
*/

--
-- Ejercicio 7. Inventar un procedimiento almacenado que permita optimizar las operaciones del gimnasio.
--

DROP PROCEDURE IF EXISTS p_controlar_aforo;

DELIMITER |

CREATE PROCEDURE p_controlar_aforo(IN inId_actividad INT)
MODIFIES SQL DATA
SQL SECURITY DEFINER
BEGIN
	DECLARE aforo, inscripciones, libre INT;
    DECLARE ocupado DECIMAL(10,2);
    
    SET aforo = (SELECT i.aforo
	FROM horario h
    INNER JOIN actividad a
		ON a.id_Actividad = h.id_actividad
	INNER JOIN instalacion i 
		ON i.id_instalacion = h.id_instalacion
	WHERE inId_actividad = a.id_Actividad
    GROUP BY h.id_actividad
    );
    
    SET inscripciones = (SELECT COUNT(id_socio)
	FROM inscripcion
    WHERE fecha_baja IS NULL AND id_actividad = inId_actividad
    GROUP BY id_actividad
    );
    
    IF inscripciones IS NULL
		THEN SET inscripciones = 0;
	END IF;
    
    SET ocupado = ROUND(( 100 - ((aforo /2) - inscripciones) / (aforo / 2) * 100), 2);
    SET libre = (aforo div 2) - inscripciones;
    
    SELECT h.id_actividad AS 'Actividad', h.id_instalacion AS 'Instalacion',
		CONCAT(h.fecha, ' ', h.hora) AS 'Horario', aforo AS 'Aforo total', 
        ocupado AS 'Ocupación', libre AS 'Plazas libres'
        FROM horario h 
        WHERE h.id_actividad = inId_actividad
        ORDER BY h.fecha;
END |
	
DELIMITER ;
     
CALL p_controlar_aforo(6);
select * from instalacion;

/* El proceso que he creado sirve para conocer el aforo disponible y el aforo en uso de una actividad programada en la tabla horario. Para ello, se presupone la siguiente regla de negocio: EL 50% DE LAS PLAZAS DE LAS ACTIVIDADES ESTÁN RESERVADAS A LOS PLANES Y EL 50% RESTANTE A INSCRIPCIONES EXTRA.
1. Creamos el procedimiento que recibe como parámetro de entrada la id de la actividad.
2. Buscamos el aforo total de la actividad mediante una sentencia SELECT con un JOIN entre las tablas actividad, horario e instalación.
3. Comprobamos el número de inscripciones extra mediante una función count() que suma el número de socios inscritos a una misma actividad siempre que los socios no se hayan dado de baja. Agrupamos el conteo por id_Actividad para que nos devuelva una única línea.
4. Calculamos el porcentaje de ocupación teniendo en cuenta que el 50% de las plazas están reservadas a los usuarios de un plan.
5. Calculamos el aforo libre teniendo en cuenta la misma regla de negocio.
6. Generamos una tabla temporal mediante una sentencia SELECT que muestre los resultados.
*/