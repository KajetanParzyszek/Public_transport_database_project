
-- Database creation with default settings


CREATE DATABASE public_transport;



-- Tables

CREATE TABLE city (
  city_id SERIAL NOT NULL,
  name    TEXT   NOT NULL UNIQUE,
  CONSTRAINT city_pkey PRIMARY KEY (city_id));
  
CREATE TABLE position (
  position_id SERIAL NOT NULL,
  name        TEXT   NOT NULL UNIQUE,
  CONSTRAINT position_pkey PRIMARY KEY (position_id));

CREATE TABLE staff (
  staff_id    SERIAL NOT NULL,
  first_name  TEXT   NOT NULL,
  last_name   TEXT   NOT NULL,
  position_id INT    NOT NULL,
  city_id     INT    NOT NULL,
  CONSTRAINT staff_pkey             PRIMARY KEY (staff_id),
  CONSTRAINT staff_position_id_fkey FOREIGN KEY (position_id) REFERENCES position (position_id),
  CONSTRAINT staff_city_id_fkey     FOREIGN KEY (city_id)     REFERENCES city (city_id));
  
CREATE TABLE vehicle_type (
  vehicle_type_id SERIAL NOT NULL,
  name            TEXT   NOT NULL UNIQUE,
  CONSTRAINT vehicle_type_pkey PRIMARY KEY (vehicle_type_id));

CREATE TABLE depot (
  depot_id        SERIAL NOT NULL,
  name            TEXT   NOT NULL UNIQUE,
  vehicle_type_id INT    NOT NULL,
  CONSTRAINT depot_pkey                 PRIMARY KEY (depot_id),
  CONSTRAINT depot_vehicle_type_id_fkey FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type (vehicle_type_id));
  
CREATE TABLE producer (
  producer_id SERIAL NOT NULL,
  name        TEXT   NOT NULL UNIQUE,
  CONSTRAINT producer_pkey PRIMARY KEY (producer_id));

CREATE TABLE model (
  model_id        SERIAL NOT NULL,
  vehicle_type_id INT    NOT NULL,
  producer_id     INT    NOT NULL,
  depot_id        INT    NOT NULL,
  name            TEXT   NOT NULL UNIQUE,
  CONSTRAINT model_pkey                 PRIMARY KEY (model_id),
  CONSTRAINT model_producer_id_fkey     FOREIGN KEY (producer_id)     REFERENCES producer (producer_id),
  CONSTRAINT model_vehicle_type_id_fkey FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type (vehicle_type_id),
  CONSTRAINT model_depot_id_fkey        FOREIGN KEY (depot_id)        REFERENCES depot (depot_id));
  
CREATE TABLE vehicle (
  vehicle_id      SERIAL NOT NULL,
  model_id        INT    NOT NULL,
  production_year INT    NOT NULL,
  CONSTRAINT vehicle_pkey          PRIMARY KEY (vehicle_id),
  CONSTRAINT vehicle_model_id_fkey FOREIGN KEY (model_id) REFERENCES model (model_id));  
  
CREATE TABLE stop (
  stop_id SERIAL NOT NULL,
  name    TEXT   NOT NULL UNIQUE,
  CONSTRAINT stop_pkey PRIMARY KEY (stop_id));
  
CREATE TABLE line (
  line_number     INT NOT NULL,
  vehicle_type_id INT NOT NULL,
  CONSTRAINT line_pkey            PRIMARY KEY (line_number),
  CONSTRAINT line_vehicle_type_id FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type (vehicle_type_id));
  
CREATE TABLE line_stop (
  line_number INT NOT NULL,
  stop_number INT NOT NULL,
  stop_id     INT NOT NULL,
  travel_time INT,
  CONSTRAINT stop_id_fkey     FOREIGN KEY (stop_id)     REFERENCES stop (stop_id),
  CONSTRAINT line_number_fkey FOREIGN KEY (line_number) REFERENCES line (line_number));

CREATE TABLE course (
  course_id   SERIAL NOT NULL,
  line_number INT    NOT NULL,
  start_time  TIME   NOT NULL,
  forward     BOOL   NOT NULL,
  staff_id    INT    NOT NULL,
  vehicle_id  INT    NOT NULL,
  CONSTRAINT course_pkey             PRIMARY KEY (course_id),
  CONSTRAINT course_line_number_fkey FOREIGN KEY (line_number) REFERENCES line (line_number),
  CONSTRAINT course_staff_id_fkey    FOREIGN KEY (staff_id)    REFERENCES staff (staff_id),
  CONSTRAINT course_vehicle_id_fkey  FOREIGN KEY (vehicle_id)  REFERENCES vehicle (vehicle_id));

CREATE TABLE ticket (
  ticket_id SERIAL        NOT NULL,
  name      TEXT          NOT NULL,
  price     DECIMAL(10,2) NOT NULL,
  validity  INTERVAL,   
  CONSTRAINT ticket_pkey PRIMARY KEY (ticket_id));

CREATE TABLE purchase (
  purchase_id   SERIAL    NOT NULL,
  ticket_id     INT       NOT NULL,
  purchase_time TIMESTAMP NOT NULL,
  CONSTRAINT purchase_pkey           PRIMARY KEY (purchase_id),
  CONSTRAINT purchase_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES ticket (ticket_id));
  

 
-- Triggers

CREATE OR REPLACE FUNCTION only_drivers_drive_function()
RETURNS TRIGGER
AS $$
  BEGIN
	IF NEW.staff_id NOT IN (SELECT s.staff_id
  						  FROM staff    AS s
  						  JOIN position AS p ON s.position_id = p.position_id
  						  WHERE p.name LIKE '%driver') THEN
      RAISE EXCEPTION 'Only drivers can be assigned to courses';
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER only_drivers_drive_trigger
BEFORE INSERT OR UPDATE ON course
FOR EACH ROW
EXECUTE FUNCTION only_drivers_drive_function();



CREATE OR REPLACE FUNCTION valid_line_number_function()
RETURNS TRIGGER 
AS $$
  BEGIN
    IF NEW.vehicle_type_id = (SELECT vehicle_type_id FROM vehicle_type WHERE name = 'Subway') THEN
      IF (NEW.line_number < 1) OR (NEW.line_number > 9) THEN
        RAISE EXCEPTION 'Invalid line number for subway. Choose a number from 1 to 9';
      END IF;
    ELSIF NEW.vehicle_type_id = (SELECT vehicle_type_id FROM vehicle_type WHERE name = 'Tram') THEN
      IF (NEW.line_number < 11) OR (NEW.line_number > 99) THEN
        RAISE EXCEPTION 'Invalid line number for tram. Choose a number from 11 to 99';
      END IF;
    ELSIF NEW.vehicle_type_id = (SELECT vehicle_type_id FROM vehicle_type WHERE name = 'Bus') THEN
      IF (NEW.line_number < 101) OR (NEW.line_number) > 999 THEN
        RAISE EXCEPTION 'Invalid line number for bus. Choose a number from 101 to 999';
      END IF;
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER valid_line_number_trigger
BEFORE INSERT OR UPDATE ON line
FOR EACH ROW
EXECUTE FUNCTION valid_line_number_function();



-- Inserting data

INSERT INTO city(name) VALUES
  ('Jawor'),
  ('Legnica'),
  ('Zlotoryja'),
  ('Strzegom'),
  ('Bolkow'),
  ('Jelenia Gora'),
  ('Wroclaw'),
  ('Swidnica'),
  ('Walbrzych'),
  ('Boleslawiec');

INSERT INTO position(name) VALUES
  ('General manager'),
  ('Depot manager'),
  ('Office worker'),
  ('Bus driver'),
  ('Tram driver'),
  ('Subway driver'),
  ('Ticket inspector'),
  ('Janitor'),
  ('Technical worker'),
  ('Security guard');
  
INSERT INTO staff(first_name, last_name, position_id, city_id) VALUES  
  ('Kajetan', 'Aarzyszek', 4,  5),
  ('Kajetan', 'Barzyszek', 5,  1),
  ('Kajetan', 'Carzyszek', 3,  6),
  ('Kajetan', 'Darzyszek', 7,  4),
  ('Kajetan', 'Earzyszek', 6,  2),
  ('Kajetan', 'Farzyszek', 8,  2),
  ('Kajetan', 'Garzyszek', 5,  1),
  ('Kajetan', 'Harzyszek', 4,  5),
  ('Kajetan', 'Iarzyszek', 9,  1),
  ('Kajetan', 'Jarzyszek', 6,  1),
  ('Kajetan', 'Karzyszek', 10, 2),
  ('Kajetan', 'Larzyszek', 9,  6),
  ('Kajetan', 'Marzyszek', 2,  1),
  ('Kajetan', 'Narzyszek', 8,  2),
  ('Kajetan', 'Oarzyszek', 8,  10),
  ('Kajetan', 'Qarzyszek', 6,  3),
  ('Kajetan', 'Rarzyszek', 4,  4),
  ('Kajetan', 'Sarzyszek', 5,  1),
  ('Kajetan', 'Tarzyszek', 10, 5),
  ('Kajetan', 'Uarzyszek', 7,  1),
  ('Kajetan', 'Varzyszek', 10, 2),
  ('Kajetan', 'Warzyszek', 4,  9),
  ('Kajetan', 'Xarzyszek', 5,  3),
  ('Kajetan', 'Yarzyszek', 5,  1),
  ('Kajetan', 'Zarzyszek', 3,  6),
  ('Aajetan', 'Parzyszek', 7,  1),
  ('Bajetan', 'Parzyszek', 2,  4),
  ('Cajetan', 'Parzyszek', 4,  1),
  ('Dajetan', 'Parzyszek', 3,  1),
  ('Eajetan', 'Parzyszek', 2,  8),
  ('Fajetan', 'Parzyszek', 5,  1),
  ('Gajetan', 'Parzyszek', 4,  2),
  ('Hajetan', 'Parzyszek', 5,  4),
  ('Iajetan', 'Parzyszek', 4,  1),
  ('Jajetan', 'Parzyszek', 4,  1),
  ('Lajetan', 'Parzyszek', 9,  1),
  ('Majetan', 'Parzyszek', 5,  7),
  ('Najetan', 'Parzyszek', 5,  5),
  ('Oajetan', 'Parzyszek', 6,  1),
  ('Pajetan', 'Parzyszek', 5,  3),
  ('Qajetan', 'Parzyszek', 3,  1),
  ('Rajetan', 'Parzyszek', 8,  3),
  ('Sajetan', 'Parzyszek', 2,  1),
  ('Tajetan', 'Parzyszek', 1,  2),
  ('Uajetan', 'Parzyszek', 2,  2),
  ('Vajetan', 'Parzyszek', 6,  7),
  ('Wajetan', 'Parzyszek', 9,  3),
  ('Xajetan', 'Parzyszek', 4,  1),
  ('Yajetan', 'Parzyszek', 6,  5),
  ('Zajetan', 'Parzyszek', 5,  1);

INSERT INTO vehicle_type(name) VALUES
  ('Bus'),
  ('Tram'),
  ('Subway');

INSERT INTO depot(name, vehicle_type_id) VALUES
  ('Przyrzecze', 2),
  ('Old Jawor',  1),
  ('Zebowice',   3),
  ('The Forge',  2),
  ('The Dairy',  1);

INSERT INTO producer(name) VALUES
  ('Solaris'),
  ('Volvo'),
  ('Mercedes-Benz'),
  ('Pesa'),
  ('Skoda'),
  ('Moderus'),
  ('Siemens');

INSERT INTO model(vehicle_type_id, producer_id, depot_id, name) VALUES
 (1, 1, 2, 'Urbino 12'),
 (1, 1, 2, 'Urbino 18'),
 (1, 2, 2, '7900'),
 (1, 3, 5, 'Citaro'),
 (1, 3, 5, 'Connnecto'),
 (2, 4, 1, 'Twist'),
 (2, 4, 1, 'Swing'),
 (2, 5, 1, '16T'),
 (2, 6, 4, 'Beta'),
 (2, 6, 4, 'Gamma'),
 (3, 7, 3, 'Inspiro');

INSERT INTO vehicle(model_id, production_year) VALUES
  (1,  2019),
  (1,  2018),
  (2,  2019),
  (2,  2019),
  (3,  2020),
  (3,  2020),
  (3,  2020),
  (4,  2017),
  (4,  2017),
  (4,  2018),
  (4,  2018),
  (5,  2017),
  (5,  2017),
  (5,  2017),
  (5,  2017),
  (6,  2016),
  (6,  2016),
  (7,  2018),
  (7,  2018),
  (7,  2018),
  (8,  2021),
  (8,  2021),
  (8,  2021),
  (8,  2021),
  (9,  2015),
  (9,  2015),
  (10, 2022),
  (10, 2022),
  (10, 2022),
  (10, 2022),
  (11, 2012),
  (11, 2012),
  (11, 2014),
  (11, 2014);
  
INSERT INTO stop(name) VALUES
  ('Sugar factory'),
  ('Army of Poland Street'),
  ('Moniuszko Street'),
  ('Main Railway Station'),
  ('The Hospital'),
  ('Zebowice'),
  ('Przyrzecze'),
  ('Park of the Peace'),
  ('Poniatowski Street'),
  ('The Old Town'),
  ('Pilsudski Street'),
  ('The Old Cinema'),
  ('Prince Bolko High School'),
  ('City Park'),
  ('The Forge'),
  ('The Forge Street'),
  ('Slowacki Street'),
  ('The School Street'),
  ('The Freedom Square'),
  ('The Castle'),
  ('The Allotment Gradens'),
  ('The Green Street'),
  ('The Mill'),
  ('The Forestry'),
  ('Jawornik'),
  ('Piotrowice Bridge'),
  ('Witos Street'),
  ('Wieniawski Street'),
  ('Lubin Street'),
  ('The Cemetery'),
  ('Limanowski Street'),
  ('Fredro Street'),
  ('Sienkiewicz Street'),
  ('The Diary'),
  ('Old Jawor'),
  ('The Old Jawor''s School'),
  ('The Side Street'),
  ('Wyszynski Street'),
  ('Korpo'),
  ('Godziszowa Way'),
  ('Krzywousty Street'),
  ('Piasts Estate'),
  ('Sikorski Street'),
  ('Chopin Street'),
  ('The Oaks Alley'),
  ('The Eastern Street'),
  ('The County Office'),
  ('Wrocław Street'),
  ('The Western Street'),
  ('Kamionka'),
  ('The Steel Street');
  
INSERT INTO line(line_number, vehicle_type_id) VALUES
  (1,   3),
  (11,  2),
  (12,  2),
  (13,  2),
  (14,  2),
  (101, 1),
  (102, 1),
  (103, 1),
  (104, 1),
  (105, 1),
  (106, 1),
  (107, 1);
  
INSERT INTO line_stop(line_number, stop_number, stop_id, travel_time) VALUES
  (1,   1,  1,  3),
  (1,   2,  2,  3),
  (1,   3,  3,  2),
  (1,   4,  4,  3),
  (1,   5,  5,  3),
  (1,   6,  6,  NULL),
  (11,  1,  7,  2),
  (11,  2,  3,  3),
  (11,  3,  8,  2),
  (11,  4,  9,  3),
  (11,  5,  10, 2),
  (11,  6,  11, 2),
  (11,  7,  12, 2),
  (11,  8,  13, 2),
  (11,  9,  14, NULL),
  (12,  1,  15, 2),
  (12,  2,  16, 3),
  (12,  3,  17, 2),
  (12,  4,  4,  1),
  (12,  5,  9,  1),
  (12,  6,  18, 2),
  (12,  7,  19, 2),
  (12,  8,  20, NULL),
  (13,  1,  21, 2),
  (13,  2,  17, 3),
  (13,  3,  4,  2),
  (13,  4,  9,  3),
  (13,  5,  22, 3),
  (13,  6,  19, 2),
  (13,  7,  20, 3),
  (13,  8,  23, 2),
  (13,  9,  24, 3),
  (13,  10, 25, NULL),
  (14,  1,  26, 3),
  (14,  2,  27, 3),
  (14,  3,  7,  2),
  (14,  4,  28, 3),
  (14,  5,  29, 2),
  (14,  6,  30, 2),
  (14,  7,  17, 3),
  (14,  8,  21, NULL),
  (101, 1,  26, 2),
  (101, 2,  27, 2),
  (101, 3,  31, 2),
  (101, 4,  19, 3),
  (101, 5,  20, 2),
  (101, 6,  23, 2),
  (101, 7,  32, 3),
  (101, 8,  33, 3),
  (101, 9,  34, NULL),
  (102, 1,  35, 3),
  (102, 2,  1,  3),
  (102, 3,  36, 2),
  (102, 4,  37, 2),
  (102, 5,  2,  2),
  (102, 6,  7,  3),
  (102, 7,  38, 3),
  (102, 8,  8,  2),
  (102, 9,  9,  2),
  (102, 10, 4,  3),
  (102, 11, 17, 3),
  (102, 12, 16, 3),
  (102, 13, 15, 3),
  (102, 14, 39, NULL),
  (103, 1,  50, 2),
  (103, 2,  51, 2),
  (103, 3,  5,  2),
  (103, 4,  12, 3),
  (103, 5,  11, 3),
  (103, 6,  10, 2),
  (103, 7,  4,  2),
  (103, 8,  17, 3),
  (103, 9,  21, 3),
  (103, 10, 40, NULL),
  (104, 1,  40, 3),
  (104, 2,  21, 3),
  (104, 3,  17, 2),
  (104, 4,  30, 3),
  (104, 5,  29, 2),
  (104, 6,  41, 3),
  (104, 7,  42, 2),
  (104, 8,  2,  2),
  (104, 9,  43, 3),
  (104, 10, 26, NULL),
  (105, 1,  25, 3),
  (105, 2,  24, 2),
  (105, 3,  23, 3),
  (105, 4,  44, 3),
  (105, 5,  13, 3),
  (105, 6,  12, 2),
  (105, 7,  45, 3),
  (105, 8,  46, 2),
  (105, 9,  6,  NULL),
  (106, 1,  39, 3),
  (106, 2,  47, 3),
  (106, 3,  48, 2),
  (106, 4,  10, 3),
  (106, 5,  9,  2),
  (106, 6,  18, 2),
  (106, 7,  19, 3),
  (106, 8,  20, NULL),
  (107, 1,  49, 2),
  (107, 2,  35, 3),
  (107, 3,  1,  3),
  (107, 4,  36, 2),
  (107, 5,  37, 2),
  (107, 6,  2,  2),
  (107, 7,  7,  3),
  (107, 8,  31, 3),
  (107, 9,  19, 2),
  (107, 10, 18, 2),
  (107, 11, 9,  2),
  (107, 12, 4,  NULL);
 
INSERT INTO course(line_number, start_time, forward, staff_id, vehicle_id) VALUES
  (1,   CAST('06:00' AS TIME), true,  5,  31),
  (1,   CAST('07:00' AS TIME), false, 5,  31),
  (1,   CAST('08:00' AS TIME), true,  5,  31),
  (1,   CAST('09:00' AS TIME), false, 5,  31),
  (1,   CAST('10:00' AS TIME), true,  16, 32),
  (1,   CAST('11:00' AS TIME), false, 16, 32),
  (1,   CAST('12:00' AS TIME), true,  16, 32),
  (1,   CAST('13:00' AS TIME), false, 16, 32),
  (1,   CAST('14:00' AS TIME), true,  10, 33),
  (1,   CAST('15:00' AS TIME), false, 10, 33),
  (1,   CAST('16:00' AS TIME), true,  10, 33),
  (1,   CAST('17:00' AS TIME), false, 10, 33),
  (1,   CAST('18:00' AS TIME), true,  46, 34),
  (1,   CAST('19:00' AS TIME), false, 46, 34),
  (1,   CAST('20:00' AS TIME), true,  46, 34),
  (1,   CAST('21:00' AS TIME), false, 46, 34),
  (11,  CAST('06:00' AS TIME), true,  2,  16),
  (11,  CAST('07:00' AS TIME), false, 2,  16),
  (11,  CAST('08:00' AS TIME), true,  2,  16),
  (11,  CAST('09:00' AS TIME), false, 2,  16),
  (11,  CAST('10:00' AS TIME), true,  2,  16),
  (11,  CAST('11:00' AS TIME), false, 7,  17),
  (11,  CAST('12:00' AS TIME), true,  7,  17),
  (11,  CAST('13:00' AS TIME), false, 7,  17),
  (11,  CAST('14:00' AS TIME), true,  7,  17),
  (11,  CAST('15:00' AS TIME), false, 7,  17),
  (11,  CAST('16:00' AS TIME), true,  18, 19),
  (11,  CAST('17:00' AS TIME), false, 18, 19),
  (11,  CAST('18:00' AS TIME), true,  18, 19),
  (11,  CAST('19:00' AS TIME), false, 18, 19),
  (11,  CAST('20:00' AS TIME), true,  18, 19),
  (11,  CAST('21:00' AS TIME), false, 18, 19),
  (12,  CAST('06:15' AS TIME), true,  23, 20),
  (12,  CAST('07:15' AS TIME), false, 23, 20),
  (12,  CAST('08:15' AS TIME), true,  23, 20),
  (12,  CAST('09:15' AS TIME), false, 23, 20),
  (12,  CAST('10:15' AS TIME), true,  23, 20),
  (12,  CAST('11:15' AS TIME), false, 23, 20),
  (12,  CAST('12:15' AS TIME), true,  24, 21),
  (12,  CAST('13:15' AS TIME), false, 24, 21),
  (12,  CAST('14:15' AS TIME), true,  24, 21),
  (12,  CAST('15:15' AS TIME), false, 24, 21),
  (12,  CAST('16:15' AS TIME), true,  24, 21),
  (12,  CAST('17:15' AS TIME), false, 31, 22),
  (12,  CAST('18:15' AS TIME), true,  31, 22),
  (12,  CAST('19:15' AS TIME), false, 31, 22),
  (12,  CAST('20:15' AS TIME), true,  31, 22),
  (12,  CAST('21:15' AS TIME), false, 31, 22),
  (13,  CAST('06:30' AS TIME), true,  33, 24),
  (13,  CAST('07:30' AS TIME), false, 33, 24),
  (13,  CAST('08:30' AS TIME), true,  33, 24),
  (13,  CAST('09:30' AS TIME), false, 33, 24),
  (13,  CAST('10:30' AS TIME), true,  33, 24),
  (13,  CAST('11:30' AS TIME), false, 33, 24),
  (13,  CAST('12:30' AS TIME), true,  37, 25),
  (13,  CAST('13:30' AS TIME), false, 37, 25),
  (13,  CAST('14:30' AS TIME), true,  37, 25),
  (13,  CAST('15:30' AS TIME), false, 37, 25),
  (13,  CAST('16:30' AS TIME), true,  37, 25),
  (13,  CAST('17:30' AS TIME), false, 38, 27),
  (13,  CAST('18:30' AS TIME), true,  38, 27),
  (13,  CAST('19:30' AS TIME), false, 38, 27),
  (13,  CAST('20:30' AS TIME), true,  38, 27),
  (13,  CAST('21:30' AS TIME), false, 38, 27),
  (14,  CAST('06:45' AS TIME), true,  40, 28),
  (14,  CAST('07:45' AS TIME), false, 40, 28),
  (14,  CAST('08:45' AS TIME), true,  40, 28),
  (14,  CAST('09:45' AS TIME), false, 40, 28),
  (14,  CAST('10:45' AS TIME), true,  40, 28),
  (14,  CAST('11:45' AS TIME), false, 40, 28),
  (14,  CAST('12:45' AS TIME), true,  40, 28),
  (14,  CAST('13:45' AS TIME), false, 50, 29),
  (14,  CAST('14:45' AS TIME), true,  50, 29),
  (14,  CAST('15:45' AS TIME), false, 50, 29),
  (14,  CAST('16:45' AS TIME), true,  50, 29),
  (14,  CAST('17:45' AS TIME), false, 50, 29),
  (14,  CAST('18:45' AS TIME), true,  50, 29),
  (14,  CAST('19:45' AS TIME), false, 50, 29),
  (14,  CAST('20:45' AS TIME), true,  50, 29),
  (101, CAST('06:00' AS TIME), true,  1,  2),
  (101, CAST('08:00' AS TIME), false, 1,  2),
  (101, CAST('10:00' AS TIME), true,  1,  2),
  (101, CAST('12:00' AS TIME), false, 1,  2),
  (101, CAST('14:00' AS TIME), true,  1,  1),
  (101, CAST('16:00' AS TIME), false, 1,  1),
  (101, CAST('18:00' AS TIME), true,  1,  1),
  (101, CAST('20:00' AS TIME), false, 1,  1),
  (102, CAST('06:10' AS TIME), true,  8,  4),
  (102, CAST('08:10' AS TIME), false, 8,  4),
  (102, CAST('10:10' AS TIME), true,  8,  4),
  (102, CAST('12:10' AS TIME), false, 8,  4),
  (102, CAST('14:10' AS TIME), true,  8,  4),
  (102, CAST('16:10' AS TIME), false, 8,  4),
  (102, CAST('18:10' AS TIME), true,  8,  4),
  (102, CAST('20:10' AS TIME), false, 8,  4),
  (103, CAST('06:20' AS TIME), true,  17, 5),
  (103, CAST('08:20' AS TIME), false, 17, 5),
  (103, CAST('10:20' AS TIME), true,  17, 5),
  (103, CAST('12:20' AS TIME), false, 17, 5),
  (103, CAST('14:20' AS TIME), true,  22, 6),
  (103, CAST('16:20' AS TIME), false, 22, 6),
  (103, CAST('18:20' AS TIME), true,  22, 6),
  (103, CAST('20:20' AS TIME), false, 22, 6),
  (104, CAST('06:30' AS TIME), true,  28, 7),
  (104, CAST('08:30' AS TIME), false, 28, 7),
  (104, CAST('10:30' AS TIME), true,  28, 7),
  (104, CAST('12:30' AS TIME), false, 28, 7),
  (104, CAST('14:30' AS TIME), true,  28, 7),
  (104, CAST('16:30' AS TIME), false, 28, 7),
  (104, CAST('18:30' AS TIME), true,  28, 7),
  (104, CAST('20:30' AS TIME), false, 28, 7),
  (105, CAST('06:40' AS TIME), true,  32, 10),
  (105, CAST('08:40' AS TIME), false, 32, 10),
  (105, CAST('10:40' AS TIME), true,  32, 10),
  (105, CAST('12:40' AS TIME), false, 32, 10),
  (105, CAST('14:40' AS TIME), true,  32, 10),
  (105, CAST('16:40' AS TIME), false, 32, 9),
  (105, CAST('18:40' AS TIME), true,  32, 9),
  (105, CAST('20:40' AS TIME), false, 32, 9),
  (106, CAST('06:50' AS TIME), true,  35, 11),
  (106, CAST('08:50' AS TIME), false, 35, 11),
  (106, CAST('10:50' AS TIME), true,  35, 11),
  (106, CAST('12:50' AS TIME), false, 35, 11),
  (106, CAST('14:50' AS TIME), true,  34, 12),
  (106, CAST('16:50' AS TIME), false, 34, 12),
  (106, CAST('18:50' AS TIME), true,  34, 12),
  (106, CAST('20:50' AS TIME), false, 34, 12),
  (107, CAST('06:00' AS TIME), true,  48, 15),
  (107, CAST('08:00' AS TIME), false, 48, 15),
  (107, CAST('10:00' AS TIME), true,  48, 15),
  (107, CAST('12:00' AS TIME), false, 48, 15),
  (107, CAST('14:00' AS TIME), true,  48, 14),
  (107, CAST('16:00' AS TIME), false, 48, 14),
  (107, CAST('18:00' AS TIME), true,  48, 14),
  (107, CAST('20:00' AS TIME), false, 48, 14);
 
INSERT INTO ticket(name, price, validity) VALUES
  ('Single',              2.00, NULL),
  ('Single reduced',      1.00, NULL),
  ('15-minute',           1.50, INTERVAL '15 minutes'),
  ('15-minute reduced',   0.70, INTERVAL '15 minutes'),
  ('Daily',               8.00, INTERVAL '1 day'),
  ('Daily reduced',       4.00, INTERVAL '1 day'),
  ('Weekly',             25.00, INTERVAL '1 week'),
  ('Weekly reduced',     12.00, INTERVAL '1 week'),
  ('Monthly',           100.00, INTERVAL '1 month'),
  ('Monthly reduced',    50.00, INTERVAL '1 month');
 
INSERT INTO purchase(ticket_id, purchase_time) VALUES
  (1,  CAST(NOW() - INTERVAL '1 minute'   AS TIMESTAMP)),
  (2,  CAST(NOW() - INTERVAL '2 minutes'  AS TIMESTAMP)),
  (1,  CAST(NOW() - INTERVAL '3 minutes'  AS TIMESTAMP)),
  (5,  CAST(NOW() - INTERVAL '4 minutes'  AS TIMESTAMP)),
  (6,  CAST(NOW() - INTERVAL '5 minutes'  AS TIMESTAMP)),
  (2,  CAST(NOW() - INTERVAL '6 minutes'  AS TIMESTAMP)),
  (3,  CAST(NOW() - INTERVAL '7 minutes'  AS TIMESTAMP)),
  (3,  CAST(NOW() - INTERVAL '8 minutes'  AS TIMESTAMP)),
  (5,  CAST(NOW() - INTERVAL '9 minutes'  AS TIMESTAMP)),
  (2,  CAST(NOW() - INTERVAL '10 minutes' AS TIMESTAMP)),
  (4,  CAST(NOW() - INTERVAL '11 minutes' AS TIMESTAMP)),
  (5,  CAST(NOW() - INTERVAL '12 minutes' AS TIMESTAMP)),
  (1,  CAST(NOW() - INTERVAL '13 minutes' AS TIMESTAMP)),
  (9,  CAST(NOW() - INTERVAL '14 minutes' AS TIMESTAMP)),
  (6,  CAST(NOW() - INTERVAL '15 minutes' AS TIMESTAMP)),
  (4,  CAST(NOW() - INTERVAL '16 minutes' AS TIMESTAMP)),
  (1,  CAST(NOW() - INTERVAL '17 minutes' AS TIMESTAMP)),
  (3,  CAST(NOW() - INTERVAL '18 minutes' AS TIMESTAMP)),
  (7,  CAST(NOW() - INTERVAL '19 minutes' AS TIMESTAMP)),
  (1,  CAST(NOW() - INTERVAL '20 minutes' AS TIMESTAMP)),
  (6,  CAST(NOW() - INTERVAL '21 minutes' AS TIMESTAMP)),
  (1,  CAST(NOW() - INTERVAL '22 minutes' AS TIMESTAMP)),
  (3,  CAST(NOW() - INTERVAL '23 minutes' AS TIMESTAMP)),
  (7,  CAST(NOW() - INTERVAL '24 minutes' AS TIMESTAMP)),
  (8,  CAST(NOW() - INTERVAL '25 minutes' AS TIMESTAMP)),
  (2,  CAST(NOW() - INTERVAL '26 minutes' AS TIMESTAMP)),
  (1,  CAST(NOW() - INTERVAL '27 minutes' AS TIMESTAMP)),
  (4,  CAST(NOW() - INTERVAL '28 minutes' AS TIMESTAMP)),
  (10, CAST(NOW() - INTERVAL '29 minutes' AS TIMESTAMP)),
  (4,  CAST(NOW() - INTERVAL '30 minutes' AS TIMESTAMP)),
  (8,  CAST(NOW() - INTERVAL '31 minutes' AS TIMESTAMP));


-- View

CREATE OR REPLACE VIEW all_data AS (
  SELECT 
	c.start_time   AS course_start_time,
	c.line_number  AS line_number,
	st.name        AS stop,
	ls.stop_number AS stop_number,
	ls.travel_time AS minutes_to_the_next_stop,
	c.forward      AS forward,
	vt.name        AS vehicle_type,
	pr.name        AS producer,
	m.name 		   AS model,
	d.name 		   AS vehicles_depot,
	s.first_name   AS drivers_first_name,
	s.last_name    AS drivers_last_name,
	p.name         AS position,
	ct.name        AS workers_city
  FROM course AS c
  JOIN staff        AS s  ON c.staff_id = s.staff_id
  JOIN city         AS ct ON s.city_id = ct.city_id
  JOIN position     AS p  ON s.position_id = p.position_id
  JOIN vehicle      AS v  ON c.vehicle_id = v.vehicle_id
  JOIN model        AS m  ON v.model_id = m.model_id
  JOIN vehicle_type AS vt ON m.vehicle_type_id = vt.vehicle_type_id
  JOIN producer     AS pr ON m.producer_id = pr.producer_id
  JOIN depot        AS d  ON m.depot_id = d.depot_id
  JOIN line_stop    AS ls ON c.line_number = ls.line_number
  JOIN stop         AS st ON ls.stop_id = st.stop_id
  ORDER BY line_number, course_start_time, stop_number 
);



-- FUNCTIONS

CREATE OR REPLACE FUNCTION update_course(
    course_id_var INT,
    column_name   TEXT,
    new_value     ANYELEMENT) 
RETURNS VOID 
AS $$
  BEGIN
    EXECUTE FORMAT('UPDATE course SET %I = $1 WHERE course_id = $2', 
				   column_name)
    USING new_value, course_id_var;
  END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION stop_schedule(
  stop_name TEXT)
RETURNS TABLE (
  course_id      INT,
  line_number    INT,
  destination    TEXT,
  departure_time TIME) 
AS $$
  BEGIN
    RETURN QUERY
    SELECT
        c.course_id,
        c.line_number,
	   (SELECT
	      s_sub.name
	    FROM line_stop AS ls_sub
	    JOIN stop      AS s_sub ON ls_sub.stop_id = s_sub.stop_id
	    WHERE ls_sub.line_number = ls.line_number
	    ORDER BY 
	      CASE WHEN c.forward     THEN ls_sub.stop_number END DESC,
	      CASE WHEN NOT c.forward THEN ls_sub.stop_number END ASC
	    LIMIT 1) AS destination,
	   (SELECT 
	      c.start_time + MAKE_INTERVAL(mins := COALESCE(CAST(SUM(ls_sub.travel_time) AS INT), 0))
	    FROM line_stop AS ls_sub
	    WHERE (ls_sub.line_number = ls.line_number) AND CASE 
		      										      WHEN c.forward THEN (ls_sub.stop_number < ls.stop_number) 
		      										      ELSE (ls_sub.stop_number >= ls.stop_number) 
		      									        END) AS departure_time
	FROM line_stop AS ls
	JOIN course    AS c ON ls.line_number = c.line_number
	JOIN stop      AS s ON ls.stop_id = s.stop_id
	WHERE (s.name = stop_name)
	ORDER BY departure_time;
  END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION connection(
  starting_stop_name TEXT,
  final_stop_name    TEXT)
RETURNS TABLE(
  course_id      INT,
  line_number    INT,
  starting_stop  TEXT,
  final_stop     TEXT,
  departure_time TIME,
  arrival_time   TIME)
AS $$
  BEGIN
    RETURN QUERY
    SELECT ss.course_id,
           ss.line_number,
           starting_stop_name,
           final_stop_name,
           ss.departure_time,
          (SELECT ss_sub.departure_time
           FROM (SELECT * FROM stop_schedule(final_stop_name)) AS ss_sub
           WHERE ss.course_id = ss_sub.course_id) AS arrival_time
    FROM (SELECT * FROM stop_schedule(starting_stop_name)) AS ss
    WHERE (SELECT ss_sub.departure_time
           FROM (SELECT * FROM stop_schedule(final_stop_name)) AS ss_sub
           WHERE ss.course_id = ss_sub.course_id) IS NOT NULL
      AND ss.departure_time < (SELECT ss_sub.departure_time
           FROM (SELECT * FROM stop_schedule(final_stop_name)) AS ss_sub
           WHERE ss.course_id = ss_sub.course_id);
  END;
$$ LANGUAGE PLPGSQL;

