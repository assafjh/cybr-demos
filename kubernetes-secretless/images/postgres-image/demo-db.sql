/* This SQL create the demo db "zoo" */

CREATE DATABASE vet;

/* connect to it */

\c vet;

CREATE TABLE zoo (
	id serial primary key,
	type VARCHAR(50),
	caregiver VARCHAR(50),
	email VARCHAR(50)
);

/* Create Application User */

CREATE USER reception PASSWORD 'vet_123456';

/* Grant Permissions */

GRANT SELECT, INSERT ON public.zoo TO reception;
GRANT USAGE, SELECT ON SEQUENCE public.zoo_id_seq TO reception;

/* Insert mock data */

insert into zoo (type, caregiver, email) values ('Blue-tongued skink', 'Eve Blaxlande', 'eblaxlande0@sohu.com');
insert into zoo (type, caregiver, email) values ('Tortoise, galapagos', 'Adah Gehricke', 'agehricke1@auda.org.au');
insert into zoo (type, caregiver, email) values ('Large-eared bushbaby', 'Martino Doulton', 'mdoulton2@discuz.net');
insert into zoo (type, caregiver, email) values ('Sambar', 'Eddie Scotland', 'escotland3@cmu.edu');
insert into zoo (type, caregiver, email) values ('Mississippi alligator', 'Dorie Embling', 'dembling4@tripadvisor.com');
insert into zoo (type, caregiver, email) values ('Eagle, african fish', 'Cindee MacCrackan', 'cmaccrackan5@mit.edu');
insert into zoo (type, caregiver, email) values ('Devil, tasmanian', 'Gaston Rame', 'grame6@huffingtonpost.com');
insert into zoo (type, caregiver, email) values ('Common green iguana', 'Agosto Keppy', 'akeppy7@hubpages.com');
insert into zoo (type, caregiver, email) values ('Zorro, common', 'Phaedra O''Loinn', 'poloinn8@google.ru');
insert into zoo (type, caregiver, email) values ('Porcupine, crested', 'Corrianne Dainton', 'cdainton9@youku.com');