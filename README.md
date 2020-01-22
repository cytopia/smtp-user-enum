# smtp-user-enum

[![](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![PyPI](https://img.shields.io/pypi/v/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Status](https://img.shields.io/pypi/status/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Format](https://img.shields.io/pypi/format/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Implementation](https://img.shields.io/pypi/implementation/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - License](https://img.shields.io/pypi/l/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)

[![Build Status](https://github.com/cytopia/smtp-user-enum/workflows/linting/badge.svg)](https://github.com/cytopia/smtp-user-enum/actions?workflow=linting)

SMTP user enumeration tool with clever timeout, retry and reconnect functionality.

Some SMTP server take a long time for initial communication (banner and greeting) and then
handle subsequent commands quite fast. Then again they randomly start to get slow again.

This implementation of SMTP user enumeration counteracts with granular timeout, retry and
reconnect options for initial communication and enumeration separately.
The defaults should work fine, however if you encounter slow enumeration, adjust the settings
according to your needs.


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

positional arguments:
  host                  IP or hostname to connect to.
  port                  Port to connect to.

optional arguments:
  -h, --help            show this help message and exit
  -v, --version         Show version information,
  -m mode, --mode mode  Mode to enumerate SMTP users.
                        Supported modes: VRFY
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


## Examples

**Note:** Output is colorized but cannot be displayed via markdown.

### Quiet output

```bash
$ smtp-user-enum -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
Start enumerating users ...
[----] 501 5.5.2 Argument required
[----] 550 5.1.1 4Dgifts... User unknown
[----] 550 5.1.1 EZsetup... User unknown
[----] 550 5.1.1 OutOfBox... User unknown
[SUCC] 250 2.1.5 root <root@mail.example.tld>
[SUCC] 250 2.1.5 <adm@mail.example.tld>
[----] 550 5.1.1 admin... User unknown
[----] 550 5.1.1 administrator... User unknown
[----] 550 5.1.1 anon... User unknown
[----] 550 5.1.1 auditor... User unknown
[----] 550 5.1.1 avahi... User unknown
[----] 550 5.1.1 avahi-autoipd... User unknown
[----] 550 5.1.1 backup... User unknown
[----] 550 5.1.1 bbs... User unknown
[TEST] bin ...
```

### Verbose output

```bash
$ smtp-user-enum -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
[1/4] Connecting to mail.example.tld:25 ...
[1/4] Waiting for banner...
[2/4] Waiting for banner...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:25:58 +0200
[1/4] Sending greeting...
[1/4] Waiting for greeting...
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
Start enumerating users ...
[Reconn 1/3] [Retry 1/5] Testing:  ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 501 5.5.2 Argument required
[Reconn 1/3] [Retry 1/5] Testing: 4Dgifts ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 4Dgifts... User unknown
[Reconn 1/3] [Retry 1/5] Testing: EZsetup ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 EZsetup... User unknown
[Reconn 1/3] [Retry 1/5] Testing: OutOfBox ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 OutOfBox... User unknown
[Reconn 1/3] [Retry 1/5] Testing: ROOT ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[SUCC] 250 2.1.5 root <root@mail.example.tld>
[Reconn 1/3] [Retry 1/5] Testing: adm ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[SUCC] 250 2.1.5 <adm@mail.example.tld>
[Reconn 1/3] [Retry 1/5] Testing: admin ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 admin... User unknown
[Reconn 1/3] [Retry 1/5] Testing: administrator ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 administrator... User unknown
[Reconn 1/3] [Retry 1/5] Testing: anon ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 anon... User unknown
[Reconn 1/3] [Retry 1/5] Testing: auditor ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 auditor... User unknown
[Reconn 1/3] [Retry 1/5] Testing: avahi ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 avahi... User unknown
[Reconn 1/3] [Retry 1/5] Testing: avahi-autoipd ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 avahi-autoipd... User unknown
[Reconn 1/3] [Retry 1/5] Testing: backup ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 backup... User unknown
[Reconn 1/3] [Retry 1/5] Testing: bbs ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[----] 550 5.1.1 bbs... User unknown
[Reconn 1/3] [Retry 1/5] Testing: bin ...
[Reconn 1/3] [Retry 1/5] Waiting for answer...
[Reconn 1/3] [Retry 2/5] Waiting for answer...
[Reconn 1/3] [Retry 3/5] Waiting for answer...
[Reconn 1/3] [Retry 4/5] Waiting for answer...
[Reconn 1/3] [Retry 5/5] Waiting for answer...
[1/4] Connecting to mail.example.tld:25 ...
[1/4] Waiting for banner...
[2/4] Waiting for banner...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:27:34 +0200
[1/4] Sending greeting...
[1/4] Waiting for greeting...
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
[Reconn 2/3] [Retry 1/5] Testing: bin ...
[Reconn 2/3] [Retry 1/5] Waiting for answer...
[SUCC] 250 2.1.5 <bin@mail.example.tld>
```


## License

**[MIT License](LICENSE.txt)**

Copyright (c) 2020 **[cytopia](https://github.com/cytopia)**
