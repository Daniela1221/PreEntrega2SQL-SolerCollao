-- Creación de la base de datos de veterinaria --

CREATE SCHEMA veterinaria;
USE veterinaria;


-- DROP SCHEMA veterinaria;

-- Creación de tablas --

-- DROP TABLE consulta;
-- DROP TABLE agenda;
-- DROP TABLE antiparasitarios;
-- DROP TABLE vacunas;
-- DROP TABLE mascota;
-- DROP TABLE historial_mascotas;
-- DROP TABLE dueño;
-- DROP TABLE historial_dueños;
-- DROP TABLE marcaantiparasitario;
-- DROP TABLE marcavacuna;
-- DROP TABLE tipoAntiparasitario;
-- DROP TABLE tipoVacuna;

CREATE TABLE dueño(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    rut VARCHAR(20) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    direccion VARCHAR(100),
    correo VARCHAR(100) NOT NULL
);

CREATE TABLE historial_dueños(
	id INT NOT NULL PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    rut VARCHAR(20) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    direccion VARCHAR(100),
    correo VARCHAR(100) NOT NULL
);

CREATE TABLE mascota(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    dueño_id INT NOT NULL,
	FOREIGN KEY (dueño_id) REFERENCES dueño(id),
    nombre VARCHAR(100) NOT NULL,
    especie VARCHAR(100) NOT NULL,
    raza VARCHAR(100) NOT NULL,
    color VARCHAR(100) NOT NULL,
    sexo VARCHAR(100) NOT NULL,
    fecha_nac DATE NOT NULL,
    esterilizado BOOLEAN NOT NULL,
    chip BOOLEAN NOT NULL, 
    peso FLOAT
);

CREATE TABLE historial_mascotas(
	id INT NOT NULL PRIMARY KEY,
    nombre_dueño VARCHAR(200) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    especie VARCHAR(100) NOT NULL,
    raza VARCHAR(100) NOT NULL,
    color VARCHAR(100) NOT NULL,
    sexo VARCHAR(100) NOT NULL,
    fecha_nac DATE NOT NULL,
    esterilizado BOOLEAN NOT NULL,
    chip BOOLEAN NOT NULL
);

CREATE TABLE tipoAntiparasitario(
	tipo_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE tipoVacuna(
	tipo_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE marcaAntiparasitario(
	marca_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE marcaVacuna(
	marca_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE antiparasitarios(
	antiparasitario_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	tipo INT NOT NULL,
    FOREIGN KEY (tipo) REFERENCES tipoAntiparasitario(tipo_id),
    marca INT NOT NULL,
    FOREIGN KEY (marca) REFERENCES marcaAntiparasitario(marca_id),
    fecha DATE NOT NULL,
    proxima_fecha DATE NOT NULL,
    mascota_id INT NOT NULL,
    FOREIGN KEY (mascota_id) REFERENCES mascota(id)
);

CREATE TABLE vacunas(
	vacuna_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	tipo INT NOT NULL,
    FOREIGN KEY (tipo) REFERENCES tipoVacuna(tipo_id),
    fecha DATE NOT NULL,
    marca INT NOT NULL,
    FOREIGN KEY (marca) REFERENCES marcaVacuna(marca_id),
    fecha_proxima DATE NOT NULL,
    mascota_id INT NOT NULL,
    FOREIGN KEY (mascota_id) REFERENCES mascota(id)
);

CREATE TABLE agenda(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	fecha DATE NOT NULL,
    nombre_dueño VARCHAR(100) NOT NULL,
    nombre_mascota VARCHAR(100) NOT NULL
);

CREATE TABLE consulta(
	consulta_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	fecha_id INT NOT NULL,
	FOREIGN KEY (fecha_id) REFERENCES agenda(id),
    razon_consulta VARCHAR(200) NOT NULL,
    peso FLOAT,
    anamnesis VARCHAR(1000) NOT NULL,
    plan_diagnostico VARCHAR(1000) NOT NULL,
    plan_terapeutico VARCHAR(1000) NOT NULL,
    prediagnostico VARCHAR(300) NOT NULL,
    diagnostico VARCHAR(300) NOT NULL,
    tratamiento VARCHAR(2000) NOT NULL,
    fecha_proxima DATE,
    mascota_id INT NOT NULL,
    FOREIGN KEY (mascota_id) REFERENCES mascota(id)
);


-- Funciones a utilizar --
-- Calculo de la edad de una mascota en base a su fecha de nacimiento --
DELIMITER $$
CREATE FUNCTION `calculo_edad`(n_fecha DATE) 
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE edad INT;
    SET edad = TIMESTAMPDIFF(YEAR, n_fecha, CURDATE()); 
	RETURN edad;
END $$

-- Concatenación de nombre y apellido a partir de la tabla dueño --
DELIMITER $$
CREATE FUNCTION `nombre_y_apellido`(nombre VARCHAR(100), apellido VARCHAR(100)) 
RETURNS VARCHAR(201)
DETERMINISTIC
BEGIN
	DECLARE nombre_completo VARCHAR(201);
    SET nombre_completo = CONCAT(nombre, ' ', apellido);
	RETURN nombre_completo;
END $$


-- TRIGGERS --
-- Dueño --
DELIMITER $$
CREATE TRIGGER respaldo_dueño
AFTER INSERT ON dueño 
FOR EACH ROW
BEGIN 
	INSERT INTO historial_dueños(id, nombre_completo, rut, telefono, direccion, correo)
	VALUES (NEW.id, nombre_y_apellido(NEW.nombre, NEW.apellido), NEW.rut, NEW.telefono, NEW.direccion, NEW.correo);
END $$

-- Mascota --
DELIMITER $$
CREATE TRIGGER respaldo_mascota
AFTER INSERT ON mascota 
FOR EACH ROW
BEGIN 
	DECLARE d_nombre VARCHAR(100);
    DECLARE d_apellido VARCHAR(100);
    
    SELECT nombre INTO d_nombre FROM dueño WHERE id = NEW.dueño_id;
    SELECT apellido INTO d_apellido FROM dueño WHERE id = NEW.dueño_id;
    
	INSERT INTO historial_mascotas(id, nombre_dueño, nombre, especie, raza, color, sexo, fecha_nac, esterilizado, chip)
	VALUES (NEW.id, nombre_y_apellido(d_nombre, d_apellido), NEW.nombre, NEW.especie, NEW.raza, NEW.color, NEW.sexo, NEW.fecha_nac, NEW.esterilizado, NEW.chip);
END $$


-- STORED PROCEDURES --
-- Buscar mascota por nombre --
DELIMITER $$
CREATE PROCEDURE nombre_mascota_repetido(IN p_nombre VARCHAR(50))
BEGIN
	SELECT * FROM mascota WHERE nombre = p_nombre;
END $$

-- Cantidad de mascotas si chip = 1 (tiene chip) o chip = 0 (no tiene chip)
DELIMITER $$
CREATE PROCEDURE contar_chips(IN numero INT)
BEGIN 
	SELECT COUNT(chip) FROM mascota WHERE chip = numero;
END $$

-- Muestra las mascotas con o sin chip
DELIMITER $$
CREATE PROCEDURE mascota_con_o_sin_chip(IN numero INT)
BEGIN
	SELECT * FROM mascota WHERE chip = numero;
END $$

-- Generación de historial de una mascota --
DELIMITER $$
CREATE PROCEDURE historial(
    IN tipo_historial VARCHAR(20),
    IN p_mascota INT
)
BEGIN
    SET @query = CONCAT('SELECT m.nombre AS "nombre mascota", a.* FROM ', tipo_historial, ' AS a ',
                        'JOIN mascota AS m ',
                        'ON m.id = a.mascota_id AND m.id =', p_mascota,
                        ' ORDER BY a.fecha DESC');
    
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END $$


-- CREACIÓN DE REGISTROS a modo de ejemplo --
-- Dueños --
INSERT INTO dueño(nombre, apellido, rut, telefono, direccion, correo) VALUES
	("Constanza", "Jimenez", "17228544-9", "+56987333455", "Comuna de San Ramón, Santiago, Chile", "constanza@gmail.com"),
    ("Fernando", "López", "7665409-1", "+56977778888", "Comuna de Las Condes, Santiago, Chile", "fernando@gmail.com"),
	("Salvador", "De la Jara", "4665980-0", "+56922335544", "Comuna de La Pintana, Santiago, Chile", "salvador@gmail.com"),
	("Luis", "Moraga", "9876778-k", "+56911435577", "Comuna de La Reina, Santiago, Chile", "luis@gmail.com"),
	("Iñaki", "Vergara", "18546770-k", "+56977640998", "Comuna de San Bernardo, Santiago, Chile", "iñaki@gmail.com");


-- Mascotas --
INSERT INTO mascota(dueño_id, nombre, especie, raza, color, sexo, esterilizado, chip, peso, fecha_nac) VALUES
	(1, "Mayra", "Perro", "Pastor Alemán", "Típico", "Hembra", true, true, 31.5, "2017-05-30"),
	(2, "Saiph", "Gato", "British Shorthair", "Gris", "Macho", true, false, 6.7, "2012-02-11"),
	(5, "Pelusa", "Perro", "Poodle", "Blanco", "Hembra", false, false, 4.3, "2020-12-15"),
	(3, "Dobby", "Perro", "Fox Terrier", "Típico", "Macho", true, true, 8.2, "2016-10-01"),
	(4, "Pelusa", "Perro", "Bichón maltés", "Blanco", "Macho", true, true, 3.8, "2022-03-21"),
	(2, "Nannuq", "Gato", "Cymric", "Negro con blanco", "Macho", true, false, 6.3, "2012-01-01"),
	(2, "Ray", "Perro", "Basset leonado de Bretaña", "Típico", "Macho", false, false, 7.8, "2019-02-05"),
	(5, "Maqui", "Perro", "Golden Retriever", "Rubio", "Macho", true, false, 28.8, "2015-06-30"),
	(5, "Copito", "Gato", "Bosque de Noruega", "Típico", "Macho", true, true, 3.7, "2014-11-20"),
	(5, "Leoncito", "Gato", "Bombay de pelo largo", "Negro", "Macho", true, false, 4.1, "2010-12-12");


-- Tipo de Antiparasitario --
INSERT INTO tipoAntiparasitario(nombre) VALUES
	('Interno'),
    ('Externo');


-- Tipo de Vacuna --
INSERT INTO tipoVacuna(nombre) VALUES
	('Antirrábica'),
    ('Óctuple'),
    ('Triple Felina'),
    ('KC');


-- Marcas --
INSERT INTO marcaAntiparasitario(nombre) VALUES
	('Simparica'),
    ('Drontal'),
    ('Bravecto');
    
    
INSERT INTO marcaVacuna(nombre) VALUES
    ('Novibac'),
    ('Versiguard'),
    ('Felocell');


-- Antiparasitarios --
INSERT INTO antiparasitarios(tipo, marca, fecha, proxima_fecha, mascota_id) VALUES
	(1, 2, "2024-04-24", "2024-07-24", 1),
	(1, 2, "2024-05-20", "2024-08-20", 1),
	(2, 3, "2023-12-24", "2024-03-24", 5),
	(1, 2, "2024-03-30", "2024-06-30", 5),
	(1, 1, "2024-07-05", "2024-10-05", 5),
	(1, 2, "2024-04-24", "2024-07-24", 3),
	(2, 3, "2022-04-24", "2022-07-24", 2),
	(1, 1, "2022-12-30", "2023-03-30", 2),
	(1, 2, "2021-11-08", "2022-02-08", 4),
	(1, 1, "2022-03-10", "2022-06-10", 4),
	(2, 3, "2022-06-17", "2022-09-17", 4);


-- Vacunas --
INSERT INTO vacunas(tipo, marca, fecha, fecha_proxima, mascota_id) VALUES
	(1, 1, "2024-01-28", "2026-01-28", 10),
	(2, 2, "2024-04-30", "2025-04-30", 9),
	(2, 1, "2023-10-10", "2024-10-10", 10),
	(3, 3, "2024-07-10", "2025-07-10", 6),
	(4, 1, "2024-05-03", "2025-05-03", 1),
	(2, 1, "2024-05-13", "2025-05-13", 1),
	(1, 2, "2024-05-13", "2026-05-13", 1),
	(2, 2, "2024-06-22", "2025-06-22", 8),
	(3, 3, "2022-10-07", "2023-10-07", 2);


-- Agenda --
INSERT INTO agenda(fecha, nombre_dueño, nombre_mascota) VALUES
	("2024-08-05", "Iñaki Vergara", "Pelusa"),
	("2024-09-20", "Catalina Ortuzar", "Manchas"),
	("2024-09-11", "Daniela Astudillo", "Yuki"),
	("2024-08-31", "Patricio Collao", "Esponjoso"),
	("2024-07-25", "Luis Moraga", "Pelusa");


-- Consultas --
INSERT INTO consulta(fecha_id, razon_consulta, peso, anamnesis, plan_diagnostico, plan_terapeutico, prediagnostico, diagnostico, tratamiento, mascota_id) VALUES
(
	1, 
    "Control para vacunas", 
    4.5, 
    "Buen estaado de salud, sin hallazgos encontrados", 
    "Proseguir con vacunaciones",
    "Ninguno",
    "Ninguno",
    "Ninguno",
    "Se aplica la vauna antirrábica y óctuple. Dejar a disposición abundante agua",
    3
);
INSERT INTO consulta(fecha_id, razon_consulta, anamnesis, plan_diagnostico, plan_terapeutico, prediagnostico, diagnostico, tratamiento, fecha_proxima, mascota_id) VALUES -- Sin peso
(
	5, 
    "Urgencia por atropello", 
    "A primera vista se ve dañada la pata izquierda trasera y la cola",
    "Se prosigue realizar radiografías y ecografía para ver daño de huesos y tejidos",
    "Requerirá terapia de movilidad una vez haya reposado por los días a determinar",
    "Fractura de para izquierda trasera",
    "Fractura interna del hueso x de la pata trasera izquierda y esguince de grado 2 en la cola",
    "Mantener movilizado y que se mueva lo menos posible. Se receta x remedio cada 12 horas por 10 días. Próximo control en 10 días",
    "2024-08-04",
    5
);


-- CONSULTAS, SUBCONSULTAS, VISTAS Y LLAMADOS DE STORED PROCEDURES --
-- Muestra la agenda de los días próximos --
CREATE OR REPLACE VIEW agenda_proxima AS 
SELECT * FROM agenda WHERE fecha >= DATE(NOW()); 

SELECT * FROM agenda_proxima;

-- Muestra las mascotas ordenadas por dueño --
CREATE OR REPLACE VIEW mascotas_por_dueño AS
SELECT * FROM mascota ORDER BY dueño_id ASC;

SELECT * FROM mascotas_por_dueño;

-- Vacunas y Antiparasitarios pendientes (1: pendiente, 0: no vencido), usando la función nombre_y_apellido --
CREATE OR REPLACE VIEW pendientes_vacunas AS 
SELECT 
	MAX(fecha_proxima) < DATE(NOW()) AS "Vencimiento Vacuna", 
    MAX(fecha_proxima) AS "Próxima Vacuna", 
    m.nombre AS "Nombre Mascota", 
    tipo AS "Tipo Vacuna", 
    nombre_y_apellido(d.nombre, d.apellido) AS "Nombre Dueño"
FROM vacunas
JOIN mascota AS m
ON vacunas.mascota_id = m.id 
JOIN dueño AS d
ON d.id = m.dueño_id
GROUP BY mascota_id, tipo
ORDER BY MAX(fecha_proxima), MAX(fecha_proxima) < DATE(NOW()) DESC;

SELECT * FROM pendientes_vacunas;

CREATE OR REPLACE VIEW pendientes_antiparasitarios AS
SELECT 
	MAX(proxima_fecha) < DATE(NOW()) AS "Vencimiento Antiparasitario", 
    MAX(proxima_fecha) AS "Próxima vacuna", 
    m.nombre AS "Nombre Mascota", 
    tipo AS "Tipo Antiparasitario", 
    nombre_y_apellido(d.nombre, d.apellido) AS "Nombre Dueño"
FROM antiparasitarios
JOIN mascota AS m
ON antiparasitarios.mascota_id = m.id 
JOIN dueño AS d
ON d.id = m.dueño_id
GROUP BY mascota_id, tipo
ORDER BY MAX(proxima_fecha), MAX(proxima_fecha) < DATE(NOW()) DESC;

SELECT * FROM pendientes_antiparasitarios;

-- Mascotas asociadas a cada dueño, usando la función nombre_y_apellido --
CREATE OR REPLACE VIEW mascotas_de_un_dueño AS
SELECT nombre_y_apellido(d.nombre, d.apellido) AS 'Nombre Dueño', m.nombre AS 'Nombre Mascota' 
FROM dueño AS d
JOIN mascota AS m
ON d.id = m.dueño_id;

SELECT * FROM mascotas_de_un_dueño;

-- Número de mascotas por dueño usando la función nombre_y_apellido -- 
CREATE OR REPLACE VIEW numero_mascotas_por_dueño AS
SELECT nombre_y_apellido(d.nombre, d.apellido) AS "Nombre Dueño", count(m.dueño_id) AS "Número de mascotas" 
FROM dueño AS d
JOIN mascota AS m
ON d.id = m.dueño_id
GROUP BY m.dueño_id;

SELECT * FROM numero_mascotas_por_dueño;

-- Nombre de mascota 'Pelusa' repetido o cualquier otro que pueda repetirse, se hace esta consulta para evitar confusiones entre distintas mascotas con el mismo nombre --
CALL nombre_mascota_repetido('Pelusa');

-- Mostrar los dueños que han puesto chip a alguna mascota, usando la función nombre_y_apellido --
CREATE OR REPLACE VIEW chip_puestos AS
SELECT nombre_y_apellido(d.nombre, d.apellido) AS 'Nombre Dueño', m.chip AS 'Chip' 
FROM dueño AS d
JOIN mascota AS m
ON d.id = m.dueño_id
WHERE chip = 1;

SELECT * FROM chip_puestos;

-- Mostrar historial de Antiparasitarios para una mascota en particular --
CALL historial('antiparasitarios', 5);

-- Historial de Vacunas para una mascota en particular --
CALL historial('vacunas', 1);

-- Cantidad de mascotas sin chip (chip = 0) -- 
CALL contar_chips(0); 

-- Mostrar las mascotas que no tienen chip, para hablar con su dueño e insentivar la incorporación de este --
CALL mascota_con_o_sin_chip(0);

-- Cálculo de la edad por mascota usando la función calculo_edad--
CREATE OR REPLACE VIEW registro_edad_mascota AS
SELECT nombre, especie, raza, color, calculo_edad(fecha_nac) AS "edad"
FROM mascota;

SELECT * FROM registro_edad_mascota;
