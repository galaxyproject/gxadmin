# Write the benchmarking functions here.
# See "Writing benchmarks" in the asv docs for more information.
import subprocess


class GxadminSuite:
    def time_query_ts_repos(self):
        gxadmin = 'q1000acb91c378353a347d6cf4078b40'
        gxadmin = subprocess.check_output(['/home/hxr/arbeit/galaxy/gxadmin/gxadmin', 'query', 'ts-repos'])
