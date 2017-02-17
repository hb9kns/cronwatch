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

# syntax for beacons: lines containing "MM URL"
#  MM=max.age in minutes for following URL (0=skip)
#  URL=beacon file to be checked (no whitespace!)
# preferably put own beacon first, so that publishing is also checked locally
#  (in that case, you may set very short max.age, as will first be updated)
# DON'T COMMIT IF PRODUCTION DATA PRESENT!
bcns="1 http://localhost/$bfn"

# report files, reset them
warn=${TEMP:-/tmp}/cronwatchwarn.txt
rprt=${TEMP:-/tmp}/cronwatchrprt.txt
: > $warn
: > $rprt

# temporary buffer file -- there should only ever be one anyway!
tmpf=${TEMP:-/tmp}/cronwatchtemp.txt

# local current epoch time in minutes
nowm=$(( `date -u +%s`/60 ))
# local hostname for reports
host=`hostname`
# timeout/sec for fetching beacon files
tout=5
# command for fetching arg.1 to stdout
# (you may need to modify depending on the tool available)
fetchit () { wget -q -t 2 -O -T $tout -w $tout "$1" ; }

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

sleep 9

# process beacons
echo $bcns | { while read maxage remurl
do if test $maxage -gt 0
 then
# empty buffer
  : >$tmpf
# and fetch beacon
  fetchit "$remurl" >$tmpf
# if not empty, fetching probably worked
  if test -s $tmpf
  then
# if nothing fetched, remote probably down
  else cat <<EOT >>$warn
* no beacon available from '$remurl' at `date -u`
EOT
  fi
 fi # skip beacon if maxage<=0
done
}

sendoff "cronwatch report" $radr <$rprt
if test -s $warn
then sendoff "cronwatch WARNING" $wadr <$warn
fi
