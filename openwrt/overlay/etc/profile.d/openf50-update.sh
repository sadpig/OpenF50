# a newer openf50-linux release (openf50-update notice, run by openf50-post at boot and every 6 hours)
[ -s /run/openf50/update-available ] && { echo; cat /run/openf50/update-available; echo; }
