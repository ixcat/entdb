
=====
entdb
=====

Overview
--------

entdb is a simple CLI/SQLite3 based datastore to support user account
metadata, presently primarily targeting a basic single-domain
user/group/netgroup/autofs NIS/Lan scenario.

Currently included:

  - support for loading/dumping of standard flat file format for:

    - v7 style /etc/passwd with shadowed password hash
    - v7 style /etc/group
    - SysV? & GNU/Linux style /etc/shadow
    - 4.3BSD style passwd (/etc/master.passwd on modern BSD-derived systems)
    - SunOS 4.x style /etc/netgroup
    - SunOS 4.x style /etc/passwd.adjunct file
    - Sendmail/4.3BSD /etc/mail/aliases file

  - generic regexp-based key:value loading/dumping (1:1 and 1:M)

System has been tested on RHEL(6/7) and OpenBSD(5.8-6.0) in both 
client/server mode, and on solaris9-11 clients.

Important security notes:

Due to lack of common portable perl hashing modules and in order
to maximize cross platform compatibility, this module uses md5
password hashes on Linux and Solaris by default. Although collisions
have been discovered in this format, it was the greatest common
denominator for compatibility in the test network, and in conjunction
with the shadowed features provided by the example configuration,
should provide reasonable protection against cracking attempts in
a typical LAN scenario, provided all machines are secured from root
compromises and physical network access is restricted.  Further
sniffing protection can be provided through the use of IPSec to
protect RPC traffic.

Dumped BSD-style passwords will use the EKsblowfish format. Provisions
exist for managing other formats in the code, though this would
entail source-level modifications.

See doc/ref/hashes.txt for more notes concerning
password hash formats. 

Installation
------------

Typical perl install::

  $ perl Makefile.PL
  $ make
  # make install

Some prerequisite modules are required:

  - DBD::SQLite
  - Crypt::PasswdMD5
  - Crypt::Eksblowfish

On RHEL::

  # yum localinstall \
  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  # yum --enablerepo=epel install perl-Crypt-PasswdMD5 \
  perl-Crypt-Eksblowfish perl-DBD-SQLite perl-ExtUtils-MakeMaker

To install a database and makefile to manage entdb generated flatfiles::

  $ make -f doc/entdb.mk installdb

This will install into /var/yp/ent by default; this location can
be customized by setting the variable ENTDIR accordingly.

If your aliases(5) file is not /etc/mail/aliases, you should set
the variable SRCALIASES to point to your systems' location. The
installdb target also requires the presence of a netgroup(5) file
- creating an empty file in /etc/netgroup should suffice if one is
not in local use.

The resulting installation will contain an entdb database in the
file ${ENTDIR}/db, which contains the available system users,
passwords, groups, netgroup entries, and mail aliases. The entdb.mk
makefile is also copied into place and has several useful targets
for maintiaining the flat files which can be generated by the entdb
script. Simply running 'make' in this directory should yield
appropriate help information, however, the key targets are 'files',
which generates all related flatfiles, and ypupdate, which will
triger a 'make' from within the configured YPDIR.

Specifically, the entdb makefile *does not* directly update the
related NIS maps - it is expected that users configure their system's
YP makefile to point to the entdb location to reference the entdb
generated files as is locally applicable - a sample set of files
is provided for this purpose and described in the section `Server
NIS Configuration`_, below.

Server NIS Configuration
------------------------

TBD in depth - install linux.mk or obsd.mk as is appropriate
to generate maps from /var/yp/ent files::

  # cp doc/linux.mk /var/yp/Makefile
  # cp doc/obsd.mk /var/yp/`domainname`/Makefile

Client NIS Configuration
------------------------

This section will be expanded with more cohesive setup docs, for
now, it contains some notes on configuring NIS lookups after yp has
been enabled as a client.

Linux
~~~~~

Pam files should contain::

  password    sufficient    pam_unix.so md5 shadow nis nullok try_first_pass use_authtok

without the 'local account only' section.

/etc/nsswitch.conf should contain::

  passwd:     compat
  shadow:     compat
  group:      files nis
  netgroup:   files nis
  aliases:    files nis

/etc/passwd & /etc/shadow:

passwd should get all data (for e.g. uid lookups)::

  # tail -n 1 /etc/passwd
  +

Correct use of Linux /etc/shadow nss_compat selectors:

Reference shadow fields are::

  # name:pass:lastchange:minage:maxage:warning:inactivity:expiredate:reserved

Where:

  - name: accountname
  - pass: enc pass
  - lastchange: last change date (unixepoch days)
  - minage: minimum days before next change (empty/0 -> none)
  - maxage: maximum days before next change (empty/0 -> disabled)
  - warning: warning days before expiry (0 -> nowarn)
  - inactivity: days valid expiry where login/forced chg allowed (0->none)
  - expiration date: days valid expiry where login/forced chg allowed (0->none)
  - reserved: unused

note: maxage disabled disables warning/inactivity/expiration functionality.

Since '0' (aka 'empty') has a meaning in the warning, inactivity,
and expiration fields, the value '-1' is used to imply pass-through
to the 'compat' NIS query [#]_.

Therefore, for NIS 'compat' selectors to pass through if wanting to override
a single field, the resulting template string is::

  +::0:0:0:-1:-1:-1:

Rather than simply::

  +::::::::

So, in the case of blocking all password hashes, the 'correct' passthrough
setting is::

  +:*:0:0:0:-1:-1:-1:

for all users allowed, allow all shadow records::

  # tail -n 1 /etc/shadow
  +::0:0:0::::

for a certain netgroup allowed, allow only the group and block rest::

  # tail -n 2 /etc/shadow
  +@foo::::::
  +:*:::::/sbin/nologin

Since linux shadow account expiry information is not common to all
platforms, it must be either generated manually or loaded separately
from the common data using the 'loadlinuxaux' command. Password
hashes are loaded generically via the 'loadgetent' command and
will work without having taken this step.

.. [#] At the time of writing (rhel7 currency), this behavior is defined
       in the function copy_spwd_changes() of glibc 2.17's compat-spwd.c.

OpenBSD
~~~~~~~

Enable NIS via master.passwd::

  # tail -n 1 /etc/master.passwd
  +:*::::::::

Solaris
~~~~~~~

For all users::

  tail -n 1 /etc/passwd
  +::::::

For netgroup only::

  tail -n 1 /etc/passwd
  +@foo::::::
  +:*:::::/sbin/nologin

