#!/bin/sh
# update own beacon and check other published ones

# flags:
# suppress standard report
quiet=no
# send warnings daily or less often
daily=no
# display sensitive data
sensitive=no
# default beacon file name
bfn=cronbeacon.html

while test "$1" != ""
do case $1 in
 -q) quiet=yes ;;
 -d) daily=yes ;;
 -s) sensitive=yes ;;
 *) cfgf="$1" ;;
 esac
 shift
done

if test "$cfgf" = ""
then cat <<EOH

usage: $0 [opt] <config>
 (2018-11-18 // HB9KNS)

options:
 -d	only warn daily: if a beacon failed already today, don't warn again
 -q	quiet: don't send report message for each run
 -s	add sensitive (but helpful) data into beacon like
	uptime, host name and current home directory
 (In most cases, once everything works, options -d and -q are useful.)

configfile lines (keywords are not case sensitive):
 BEACON mm url
   mm=max.age in minutes for following URL (0=skip)
   url=beacon file to be checked (no whitespace!)
   put own beacon first with low mm, to immediately check local beacon
   ('%bfn%' in url will be replaced by BFILE, see below)
 WARN addr : email address (or user name) for warn messages
 REPORT addr : for regular report messages (same as WARN if missing)
   ('.' addresses suppress emails and instead report to STDERR)
 BDIR path : local writable publication path for own beacon
 BFILE name : (inactive, see source; currently '$bfn')
 (other keywords are ignored, i.e '#' for comments is ok)

EOH
 exit
fi

if test ! -s "$cfgf"
then cat <<EOT

### config file '$cfgf' unreadable or empty, aborting!

EOT
 exit 1
fi

# get lines from arg.2 with case-independent prefixed arg.1, remove prefix
# with SPC and TAB in [..] patterns
getlines () { grep -i "^$1" "$2" | sed -e 's/[^	 ]*[ 	]*//' ; }

# address for warnings, you may put an external one instead of $USER
# to use as default // BUT THEN DON'T GIT PUSH TO REMOTE!
wadr=`getlines WARN "$cfgf"|tail -n 1`
wadr=${wadr:-"$USER"}
# address for regular reports (for no reporting, leave empty or comment out)
radr=`getlines REPORT "$cfgf"|tail -n 1`
# if undefined, use warn address
radr=${radr:-"$wadr"}

# standard beacon file name (only letters, numbers, dots)
# uncomment following line, if you want to permit configurable name
# bfn=`getlines BFILE "$cfgf"|tail -n 1`
bfn=${bfn:-cronbeacon.html}
# local (writable) beacon path
lbcn=`getlines BDIR "$cfgf"|tail -n 1`
# append file name
lbcn=${lbcn:-"$HOME/public_html"}/$bfn

# substitute variables: this allows to use $HOME, $USER etc as arguments
# for security reasons, permit only CONTROLLED and SANITIZED input!
eval wadr="$wadr"
eval radr="$radr"
eval bfn="$bfn"
eval lbcn="$lbcn"

# base for temporary and report files
tfbase=${TMPDIR:-/tmp}/croncrowdX$USER

# report files, reset them
warn=$tfbase-warn.txt
rprt=$tfbase-rprt.txt
: > $warn
: > $rprt
chmod 600 $warn $rprt

# memory file, in case only daily warnings (-d flag)
# (doesn't matter if it disappears after reboot)
memo=$tfbase-memo.txt

# lowest permitted age difference (negative) in minutes,
# to permit faster going remote clocks
llim=-2

# temporary buffer file -- there should only ever be one!
tmpf=$tfbase-temp.txt

# local current epoch time in minutes
nowm=$(( `date -u +%s`/60 ))
# local date
today=`date -u '+%Y-%m-%d'`
# local hostname for reports
host=`hostname`
# timeout/sec for fetching beacon files
tout=9
# command for fetching arg.1 to stdout
# (you may need to modify depending on the tool available)
# forget about certificate checking -- low security needed here
#fetchit () { wget --no-check-certificate -q -t 2 -O - -T $tout -w $tout "$1" ; }
#fetchit () { curl -k -m $tout -s "$1" ; }
fetchit () { lynx -source -connect_timeout=$tout -nolist -notitle -read_timeout=$tout "$1" ; }

# do not change anything below!

# marker for beacon epoch time (only non-special chars for grep/sed, no ';')
# should be followed only by white space or colon, and epoch time on same line
betm='==ETM=='

# send stdin to address in arg.2 (or stderr if empty/missing)
# with subject in arg.1
sendoff () {
 if test "$2" = "" -o "$2" = "."
# no recipients, then to stderr
 then
  echo "# $1" >&2
  cat >&2
 else cat | mail -s "$1" "$2"
 fi
}

# update own beacon
# privacy relevant data must be explicitly permitted
if test $sensitive = yes
then cat <<EOT >$lbcn
// $host $HOME
`uptime`
`date -u`
EOT
else : > $lbcn
fi
# in any case display time stamp
# (no whitespace behind marker to prevent line break)
cat <<EOT >>$lbcn
$betm:$nowm
EOT
chmod a+r $lbcn

sleep 9

# process beacon list, replace '%bfn%' by $bfn
getlines BEACON "$cfgf" | sed -e "s/%bfn%/$bfn/" | {
# flag whether warn message must be sent
dowarn=no
# flag whether current beacon failed
bfail=yes
# list of beacons that failed just now
bhashes=''
while read maxage remurl
# only process beacons with positive maxage
do if test $maxage -gt 0
 then
# empty buffer
  : > $tmpf
  chmod 600 $tmpf
# create "hash" for this beacon
  bhsh=`echo ":$today:$remurl" | tr -c '0-9:%/A-Za-z-' -`
# and fetch beacon
### for debugging
##echo ::::: $remurl >>$tmpf.raw
  fetchit "$remurl" >$tmpf
##cat $tmpf >>$tmpf.raw
##echo :---: >>$tmpf.raw
# not empty? fetching probably worked
  if test -s $tmpf
  then
# get last line with marker, remove leading marker and colon/whitespace
   rt=`grep $betm $tmpf 2>/dev/null | tail -n 1 | sed -e "s;.*$betm[: 	]*;;"`
# allow only numbers, and set to 0 if missing
   rt=`echo $rt | tr -c -d '0-9'`
   age=$(( $nowm-${rt:-0} ))
   if test $age -lt $llim -o $age -gt $maxage
   then cat <<EOT >>$warn
* age '$age' from '$remurl' out of range [$llim .. $maxage]
EOT
   bfail=yes
   else cat <<EOT >>$rprt
+ age '$age' from '$remurl' is ok
EOT
   bfail=no
   fi
# nothing received? remote probably down, fail for sure
  else cat <<EOT >>$warn
- no beacon available from '$remurl' at `date -u`
EOT
   bfail=yes
  fi

# decide about need to warn:
  if test $bfail = yes
# add to list of failing beacons
  then bhashes="$bhashes
$bhsh"
# did it already fail today?
   if grep $bhsh $memo >/dev/null 2>&1
# then just add remark in normal report
   then cat <<EOT >>$rprt
* earlier problem with '$remurl' today
EOT
# if 1st time today, then warn
   else dowarn=yes
   fi
  fi

 fi # skip beacon if maxage<=0
done

# save list of beacons failing today
echo "$bhashes" >$memo
chmod 600 $memo

# suppress warning, if only daily, and nothing failed just now
if test $daily = yes -a $dowarn = no
then : > $warn
fi
}

# footer for report and warning
cat <<EOT >$tmpf

---

generated by $0
running on `hostname`
at `date -u`
with local beacon time $nowm
EOT

cat $tmpf >>$rprt

if test $quiet = no
then sendoff "croncrowd report" $radr <$rprt
fi
# only send non-empty warnings
if test -s $warn
then
 cat $tmpf >>$warn
 sendoff "croncrowd WARNING" $wadr <$warn
fi
