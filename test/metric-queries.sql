BEGIN;
SET LOCAL statement_timeout = '30s';
-- All query source names are shadowed, including the optional email filter.
-- No Galaxy installation or persistent fixture records are required.
CREATE TEMP TABLE job (id bigint, tool_id text, state text, user_id bigint, create_time timestamp, update_time timestamp);
CREATE TEMP TABLE job_metric_numeric (job_id bigint, plugin text, metric_name text, metric_value numeric(26,7));
CREATE TEMP TABLE galaxy_user (id bigint, email text);
CREATE TEMP TABLE dataset (id bigint, file_size numeric, total_size numeric);
CREATE TEMP TABLE history_dataset_association (id bigint, dataset_id bigint, extension text);
CREATE TEMP TABLE job_to_input_dataset (id bigint, job_id bigint, dataset_id bigint);
INSERT INTO job SELECT n, 'fixture_' || n, 'ok', n, '2090-01-01'::timestamp, '2090-01-01'::timestamp FROM generate_series(1,12) n;
UPDATE job SET tool_id='fixture_1' WHERE id=12;
INSERT INTO dataset VALUES (10,100,100),(20,250,250),(100,99999,99999);
INSERT INTO history_dataset_association VALUES (100,10,'txt'),(200,20,'txt');
INSERT INTO job_to_input_dataset VALUES (1,1,100),(2,1,200);
INSERT INTO job_metric_numeric VALUES
(1,'core','runtime_seconds',3600),
(1,'core','galaxy_slots',2),
(1,'core','galaxy_memory_mb',1024),
(2,'core','runtime_seconds',7200),
(2,'core','galaxy_slots',4),
(2,'core','galaxy_memory_mb',2048),
(3,'core','runtime_seconds',3600),
(3,'core','galaxy_slots',2),
(3,'core','galaxy_memory_mb',1024),
(4,'core','runtime_seconds',3600),
(4,'core','galaxy_slots',2),
(4,'core','galaxy_memory_mb',1024),
(5,'core','runtime_seconds',3600),
(5,'core','galaxy_slots',1),
(5,'core','galaxy_memory_mb',1024),
(6,'core','runtime_seconds',3600),
(6,'core','galaxy_slots',2),
(6,'core','galaxy_memory_mb',1024),
(7,'core','runtime_seconds',3600),
(7,'core','galaxy_slots',1),
(7,'core','galaxy_memory_mb',1024),
(9,'core','runtime_seconds',0),
(9,'core','galaxy_slots',0),
(9,'core','galaxy_memory_mb',0),
(10,'core','runtime_seconds',3600),
(10,'core','galaxy_slots',2),
(10,'core','galaxy_memory_mb',1024),
(11,'core','runtime_seconds',3600),
(11,'core','galaxy_memory_mb',1024),
(12,'core','runtime_seconds',3600),
(12,'core','galaxy_slots',2),
(1,'core','galaxy_slots',2),
(2,'core','galaxy_slots',4),
(3,'core','runtime_seconds',7200),
(4,'core','galaxy_slots',3),
(7,'core','runtime_seconds',NULL),
(1,'cgroup','memory.max_usage_in_bytes',536870912),
(1,'cgroup','memory.memsw.max_usage_in_bytes',9663676416),
(1,'cgroup','cpuacct.usage',1800000000000),
(2,'cgroup','memory.peak',1073741824),
(2,'cgroup','memory.peak',1073741824),
(2,'cgroup','cpu.stat.usage_usec',3600000000),
(3,'cgroup','memory.peak',536870912),
(4,'cgroup','memory.peak',536870912),
(4,'cgroup','memory.peak',805306368),
(4,'cgroup','cpuacct.usage',1800000000000),
(5,'cgroup','memory.memsw.max_usage_in_bytes',9663676416),
(6,'cgroup','memory.peak',536870912),
(6,'cgroup','memory.max_usage_in_bytes',536870912),
(6,'cgroup','cpuacct.usage',1800000000000),
(6,'cgroup','cpu.stat.usage_usec',1800000000),
(7,'cgroup','memory.peak',0),
(9,'cgroup','memory.peak',0),
(9,'cgroup','cpu.stat.usage_usec',0),
(10,'cgroup','memory.peak',536870912),
(10,'cgroup','memory.peak',NULL),
(11,'cgroup','memory.peak',536870912),
(11,'cgroup','cpu.stat.usage_usec',1800000000),
(12,'cgroup','memory.peak',10737418240),
(1,'wrong_plugin','runtime_seconds',999999),
(1,'wrong_plugin','galaxy_slots',999999),
(1,'wrong_plugin','galaxy_memory_mb',999999),
(1,'wrong_plugin','memory.max_usage_in_bytes',999999),
(1,'wrong_plugin','memory.peak',999999),
(1,'wrong_plugin','cpuacct.usage',999999);
