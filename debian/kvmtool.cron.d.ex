#
# Regular cron jobs for the kvmtool-0 package
#
0 4	* * *	root	[ -x /usr/bin/kvmtool-0_maintenance ] && /usr/bin/kvmtool-0_maintenance
