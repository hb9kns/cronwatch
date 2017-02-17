#!/bin/sh
# update own beacon and check other published ones
# 2017-02-17 YBonetti

# address for warnings, you may put your own here -- BUT THEN DON'T COMMIT!
wadr=${CRONWATCH-ADDR:-"john@example.com"}
# address for regular reports (for no reporting, leave empty or comment out)
radr=$wadr

# standard beacon file name (only letters, numbers, dots)
bfn=cronbeacon.html
# local (writable) beacon path
lbcn="$HOME/public_html/$bfn"
# syntax for beacons: "MM1 URL1 MM2 URL2 ..."
#  MM=max.age in minutes for following URL
#  URL=beacon file to be checked (no whitespace!)
# preferably put own beacon first, so that publishing is also checked locally
#  (in that case, you may set very short max.age, as will first be updated)
# DON'T COMMIT IF PRODUCTION DATA PRESENT!
bcns="1 http://localhost/$bfn"

# local current epoch time in minutes
nowm=$(( `date -u +%s`/60 ))

# do not change anything below!

# marker for beacon epoch time (preferably non-special chars for grep/sed)
# should be followed only by white space and epoch time on same line
betm=':::ET:::'

# update own beacon

cat <<EOT >$lbcn
`uptime`

$betm $nowm
EOT
chmod a+r $lbcn
