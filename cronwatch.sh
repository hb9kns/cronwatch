#!/bin/sh
# update own beacon and check other published ones
# 2017-02-17 YBonetti

# address for warnings, you may put an external one instead of $USER
# // BUT THEN DON'T COMMIT!
wadr=${CRONWATCHADDR:-"$USER"}
# address for regular reports (for no reporting, leave empty or comment out)
radr=$wadr

# standard beacon file name (only letters, numbers, dots)
bfn=cronbeacon.html
# local (writable) beacon path
lbcn=${CRONWATCHPUBDIR:-"$HOME/public_html/"}$bfn
# local hostname for reports
host=`hostname`
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
betm='==ETM=='

# send stdin to address in arg.2 (or stderr if empty/missing)
# with subject in arg.1
sendoff () {
 if test "$2" = ""
# no recipients, then to stderr
 then
  echo "# $1" >&2
  cat >&2
 else cat | mail -s "$1" "$2"
 fi
}

# update own beacon

cat <<EOT >$lbcn
`date -u` // $host
`uptime`
$betm $nowm
EOT
chmod a+r $lbcn
