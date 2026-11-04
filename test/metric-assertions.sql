CREATE TEMP TABLE expected_jobs (job_id bigint, total_filesize numeric, num_files bigint, runtime_seconds numeric, slots numeric, memory_bytes numeric);
INSERT INTO expected_jobs VALUES
(1,350,2,3600,2,536870912), (2,NULL,NULL,7200,4,1073741824),
(3,NULL,NULL,NULL,2,536870912), (4,NULL,NULL,3600,NULL,NULL),
(5,NULL,NULL,3600,1,NULL), (6,NULL,NULL,3600,2,NULL),
(7,NULL,NULL,NULL,1,0), (8,NULL,NULL,NULL,NULL,NULL),
(9,NULL,NULL,0,0,0), (10,NULL,NULL,3600,2,NULL),
(11,NULL,NULL,3600,NULL,536870912), (12,NULL,NULL,3600,2,10737418240);
DO $$ BEGIN
IF EXISTS (
 (SELECT job_id,total_filesize,num_files,runtime_seconds,slots,memory_bytes FROM actual_jobs EXCEPT ALL SELECT * FROM expected_jobs)
 UNION ALL
 (SELECT * FROM expected_jobs EXCEPT ALL SELECT job_id,total_filesize,num_files,runtime_seconds,slots,memory_bytes FROM actual_jobs)
) THEN RAISE EXCEPTION 'job-metrics regression'; END IF;
IF (SELECT count(*) FROM actual_inputs) <> 1
 OR NOT EXISTS (SELECT FROM actual_inputs WHERE id=1 AND input_count=2 AND memory_used_mb=512 AND extensions='txt')
 THEN RAISE EXCEPTION 'tool-memory-per-inputs regression'; END IF;
IF (SELECT count(*) FROM actual_memory) <> 4
 OR NOT EXISTS (SELECT FROM actual_memory WHERE tool_id='fixture_1' AND run_count=1 AND avg_mem_used_gb=0.5 AND avg_mem_allocated_gb=1 AND avg_mem_percent=50)
 OR NOT EXISTS (SELECT FROM actual_memory WHERE tool_id='fixture_2' AND run_count=1 AND avg_mem_used_gb=1 AND avg_mem_allocated_gb=2 AND avg_mem_percent=50)
 OR NOT EXISTS (SELECT FROM actual_memory WHERE tool_id='fixture_11' AND avg_mem_percent=50)
 OR NOT EXISTS (SELECT FROM actual_memory WHERE tool_id='fixture_9' AND avg_mem_used_gb=0 AND avg_mem_percent IS NULL)
 THEN RAISE EXCEPTION 'tool-memory-efficiency regression'; END IF;
IF (SELECT count(*) FROM actual_resources) <> 8
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_1' AND jobs=2 AND runtime_hrs=2 AND core_hrs=4 AND cpu_hrs=0.5 AND cpu_eff_pct=25 AND mem_eff_pct=50 AND avg_mem_gb=5.25)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_2' AND core_hrs=8 AND cpu_hrs=1 AND mem_eff_pct=50)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_4' AND core_hrs IS NULL AND cpu_hrs IS NULL AND avg_mem_gb IS NULL)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_5' AND avg_mem_gb IS NULL)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_6' AND avg_mem_gb IS NULL AND cpu_hrs IS NULL)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_9' AND core_hrs=0 AND cpu_hrs=0 AND cpu_eff_pct IS NULL)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_10' AND avg_mem_gb IS NULL)
 OR NOT EXISTS (SELECT FROM actual_resources WHERE tool_id='fixture_11' AND core_hrs IS NULL AND cpu_hrs IS NULL)
 THEN RAISE EXCEPTION 'tool-resource-usage regression'; END IF;
-- Usable allocation: 2+8+1+2+0+2+2 = 17 hours. Conflicts excluded.
IF (SELECT count(*) FROM actual_monthly) <> 1
 OR NOT EXISTS (SELECT FROM actual_monthly WHERE month='2090-01-01' AND cpu_hours=17 AND cpu_years=0 AND nb_users=10)
 THEN RAISE EXCEPTION 'monthly-cpu-stats regression'; END IF;
IF (SELECT count(*) FROM actual_years) <> 1
 OR NOT EXISTS (SELECT FROM actual_years WHERE month='2090-01-01' AND cpu_years=0)
 THEN RAISE EXCEPTION 'monthly-cpu-years regression'; END IF;
END $$;
ROLLBACK;
\echo Metric query regression checks passed
