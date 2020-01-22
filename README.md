# smtp-user-enum

[![](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![PyPI](https://img.shields.io/pypi/v/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Status](https://img.shields.io/pypi/status/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Format](https://img.shields.io/pypi/format/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Implementation](https://img.shields.io/pypi/implementation/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - License](https://img.shields.io/pypi/l/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)

[![Build Status](https://github.com/cytopia/smtp-user-enum/workflows/linting/badge.svg)](https://github.com/cytopia/smtp-user-enum/actions?workflow=linting)

SMTP user enumeration via `VRFY` and `EXPN` with clever timeout, retry and reconnect functionality.

Some SMTP server take a long time for initial communication (banner and greeting) and then
handle subsequent commands quite fast. Then again they randomly start to get slow again.

This implementation of SMTP user enumeration counteracts with granular timeout, retry and
reconnect options for initial communication and enumeration separately.
The defaults should work fine, however if you encounter slow enumeration, adjust the settings
according to your needs.

Additionally if it encounters anything like `421 Too many errors on this connection` it will
automatically and transparently reconnect and continue from where it left off.


## Installation
```bash
pip install smtp-user-enum
```


## Usage

```bash
$ smtp-user-enum --help

usage: smtp-user-enum [options] -u/-U host port
       smtp-user-enum --help
       smtp-user-enum --version

SMTP user enumeration tool with clever timeout, retry and reconnect functionality.

Some SMTP server take a long time for initial communication (banner and greeting) and then
handle subsequent commands quite fast. Then again they randomly start to get slow again.

This implementation of SMTP user enumeration counteracts with granular timeout, retry and
reconnect options for initial communication and enumeration separately.
The defaults should work fine, however if you encounter slow enumeration, adjust the settings
according to your needs.

Additionally if it encounters anything like '421 Too many errors on this connection' it will
automatically and transparently reconnect and continue from where it left off.


positional arguments:
  host                  IP or hostname to connect to.
  port                  Port to connect to.

optional arguments:
  -h, --help            show this help message and exit
  -v, --version         Show version information,
  -m mode, --mode mode  Mode to enumerate SMTP users.
                        Supported modes: VRFY, EXPN
                        Default: VRFY
  -d, --debug           Show debug output. Useful to adjust your timing and retry settings.
  -u user, --user user  Username to test.
  -U file, --file file  Newline separated wordlist of users to test.
  --timeout-init sec    Timeout for initial communication (connect, banner and greeting).
                        Default: 25
  --timeout-enum sec    Timeout for user enumeration.
                        Default: 10
  --retry-init int      Number of retries for initial communication (connect, banner and greeting).
                        Default: 4
  --retry-enum int      Number of retries for user enumeration.
                        Default: 5
  --reconnect int       Number of reconnects during user enumeration after retries have exceeded.
                        Default: 3
```


## VRFY mode (default)

> The SMTP "VRFY" command allows you to verify whether a the system can deliver mail to a particular user.
>
> Source: https://www.rapid7.com/db/vulnerabilities/smtp-general-vrfy

### Successful VRFY mode output

```bash
$ smtp-user-enum -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
Start enumerating users with VRFY mode ...
[----] admin             550 5.1.1 admin... User unknown
[----] OutOfBox          550 5.1.1 OutOfBox... User unknown
[SUCC] root              250 2.1.5 root <root@mail.example.tld>
[SUCC] adm               250 2.1.5 <adm@mail.example.tld>
[----] avahi-autoipd     550 5.1.1 avahi-autoipd... User unknown
[----] backup            550 5.1.1 backup... User unknown
[TEST] bin ...
```

### Failed VRFY mode output

In case the VRFY mode is not successful as shown below, you will need to try out a different mode.

```bash
$ smtp-user-enum -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
Start enumerating users with VRFY mode ...
[----] 4Dgifts           502 VRFY disallowed.
[----] EZsetup           502 VRFY disallowed.
[----] OutOfBox          502 VRFY disallowed.
[----] root              502 VRFY disallowed.
[----] adm               502 VRFY disallowed.
[----] admin             502 VRFY disallowed.
[----] administrator     502 VRFY disallowed.
[----] anon              502 VRFY disallowed.
```


## EXPN mode

> The SMTP "EXPN" command allows you to expand a mailing list or alias, to see where mail addressed to the alias actually goes. For example, many organizations alias postmaster to root, so that mail addressed to postmaster will get delivered to the system administrator. Issuing "EXPN postmaster" via SMTP would reveal that postmaster is aliased to root.
>
> The "EXPN" command can be used by attackers to learn about valid usernames on the target system. On some SMTP servers, EXPN can be used to show the subscribers of a mailing list -- subscription lists are generally considered to be sensitive information.
>
> Source: https://www.rapid7.com/db/vulnerabilities/smtp-general-expn

### Successful EXPN mode output

```bash
$ smtp-user-enum -m EXPN -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
Start enumerating users with EXPN mode ...
[----] 4Dgifts           550 5.1.1 4Dgifts... User unknown
[----] EZsetup           550 5.1.1 EZsetup... User unknown
[----] OutOfBox          550 5.1.1 OutOfBox... User unknown
[SUCC] root              250 2.1.5 root <root@barry>
[SUCC] adm               250 2.1.5 root <root@barry>
[----] admin             550 5.1.1 admin... User unknown
[----] administrator     550 5.1.1 administrator... User unknown
[----] anon              550 5.1.1 anon... User unknown
[----] auditor           550 5.1.1 auditor... User unknown
```

**Note:** the right side shows to what mailbox the email will be forwarded for the alias.

### Failed EXPN mode output

In case the EXPN mode is not successful as shown below, you will need to try out a different mode.

```bash
$ smtp-user-enum -m EXPN -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
Start enumerating users with EXPN mode ...
[----] adm               502 Unimplemented command.
[----] admin             502 Unimplemented command.
[----] administrator     502 Unimplemented command.
[----] anon              502 Unimplemented command.
[----] auditor           502 Unimplemented command.
[----] avahi             502 Unimplemented command.
[----] avahi-autoipd     502 Unimplemented command.
[----] bbs               502 Unimplemented command.
[----] bin               502 Unimplemented command.
```


## License

**[MIT License](LICENSE.txt)**

Copyright (c) 2020 **[cytopia](https://github.com/cytopia)**
