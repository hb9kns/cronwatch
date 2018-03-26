# cronwatch script

_also see source code and usage info (by running script without arguments)_

## `croncrowd.sh`

### intro

If you run any kind of UNIX machine, you're probably familiar with
`crontab` and cronjobs. You may also use it to monitor the status of
your systems. But what if the cron daemon itself fails?
If you have more than one machine at your disposal for cronjobs,
they can monitor each other,
and this is where `croncrowd.sh` comes into play. 

`croncrowd.sh` runs on each participating machine, publishes (in
some externally accessible directory) a short beacon file,
tries to get the corresponding beacon file from all other
machines, and checks whether their timestamps are not too distant
in the past.  Based on that, it can generate and send a report (if
all is fine) or a warning message to a receiving address, to alert
you or keep you informed.

*Note: versions before 2017-11-08 are not compatible with newer ones!*
Please update all instances to the new version, otherwise missing
beacons will be reported by old version instances.

### files

- `croncrowd.sh` is the script itself; it should work with any common shell
  like `sh` / `bash` / `dash` / `ksh` or similar.
- a configuration file, readable by the script, for example
  located at `$HOME/.croncrowd` and containing
  definitions, local parameters, and remote beacon URLs
- temporary files, normally in `/tmp/` and called `croncrowd*.txt`,
  which must be readable and writable by the script

### usage

_See also help provided by the script, if called without arguments._

#### options

- `-d` for sending not more than one daily warning message for a
  continuously failing remote beacon. If you don't give this option,
  the script will send a warning at each run if a beacon fails, which
  can be rather annoying, if you already received a warning.
- `-q` for suppressing the report when everything is ok.
- `-s` for adding some sensitive data to the beacon file. By default,
  only the timestamp for the script itself is added. With this option,
  also uptime, system time, hostname, and home directory are displayed.
  This may be useful if you want to remotely check on the load of the
  system, but it may give away sensitive data.

For normal operation, options `-d -q` are recommended.

#### config file

The name of the config file must be given to the script as argument.
It consists of lines with the following keywords:

##### `BEACON` mm url

mm is the maximum allowed age (in minutes) of the remote beacon.

If the remote beacon is older, it's cronjob facility is assumed
malfunctioning, which will result in a warning generated by the script.
This time span of course must be related to the frequency of execution
of the remote `croncrowd.sh` script.
If mm is 0, this particular beacon will not be checked at all.

url is the location where the remote beacon file can be accessed.
Only HTTP(S) and gopher have been tested as protocol (with lynx).
The url should not contain any whitespace.

`%bfn%` in url will be replaced by the beacon file name (see `BFILE`)
as defined by the script.

You may list an URL for the local system as well, to verify
your local webserver is working correctly. In that case, you can
set a low number for mm, as the local beacon will be set by the script
immediately before the beacons are checked.

If an URL cannot be accessed (file not retrieved), this will also
be treated as failure, generating a warning message from the script.

##### `WARN` addr

Address (or user name) to receive warning messages by e-mail.
If undefined, `$USER` will be used instead.

If option `-d` is given, warnings for a beacon will be suppressed,
if there were already warnings sent out the same day.

##### `REPORT` addr

Address (or user name) to receive report messages by e-mail.
If undefined, the argument to `WARN` will be used instead.

Report messages are sent at each run, unless suppressed with option `-q`
as discussed above.

##### `BDIR` path

Local writable publication path for own beacon.

In this directory the local beacon file will be written,
for remote access by remote `croncrowd.sh` instances.

##### `BFILE` name

Name of beacon file, will also replace `%bfn%` in remote beacon URLs.

_This is currently inactive, and the name is hardwired into the script._
_See script source code, if you want to set this active._

`cronbeacon.html` is the default name.

#### Notes

- You may use local shell variables like `$HOME` or `$USER` etc
  for the arguments to `WARN, REPORT, BDIR, BFILE,`
  as these will be processed by `eval` shell command.
- All other keywords are ignored, therefore you can use e.g '#' or ';' or '%' for comment lines.
- The format of `BFILE` is not HTML but plain text, even if the default
  name says so. The suffix `.html` helps with most HTTP servers,
  but for the script itself, it is irrelevant.

#### Example

	warn    john@example.com
	# report unset, then same as warn
	# report        $USER+croncrowd
	bdir    $HOME/public_html
	# beacon list
	# %bfn% will be replaced by $bfn as defined in script
	beacon	9	http://localhost/%bfn%
	beacon	3600	http://www.example.org/%bfn%
	# ignore the following (max.age=0)
	beacon	0	gopher://www.nowhere.net/0/%bfn%

### Installation

1. create `.croncrowd` (or whatever you prefer for the configuration file name) as discussed above
2. if you prefer using e.g `wget` instead of `lynx` to fetch beacon data, please modify the definition of the `fetchit` function
3. install cronjob for `sh croncrowd.sh -q -d $HOME/.croncrowd`
   (with options and config file location according to your preferences)
4. for testing, you can of course launch the script also directly e.g `sh croncrowd.sh .croncrowd`

---

_(2018-Mar, HB9KNS)_
