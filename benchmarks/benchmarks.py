# Write the benchmarking functions here.
# See "Writing benchmarks" in the asv docs for more information.
import subprocess


class GxadminSuite:
    def time_query_ts_repos(self):
        gxadmin = 'q1000acb91c378353a347d6cf4078b40'
        subprocess.check_output('./gxadmin query ts-repos')
