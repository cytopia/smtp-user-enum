# smtp-user-enum

[![](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![PyPI](https://img.shields.io/pypi/v/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Status](https://img.shields.io/pypi/status/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Format](https://img.shields.io/pypi/format/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - Implementation](https://img.shields.io/pypi/implementation/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)
[![PyPI - License](https://img.shields.io/pypi/l/smtp-user-enum)](https://pypi.org/project/smtp-user-enum/)

[![Build Status](https://github.com/cytopia/smtp-user-enum/workflows/linting/badge.svg)](https://github.com/cytopia/smtp-user-enum/actions?workflow=linting)

SMTP user enumeration via `VRFY`, `EXPN` and `RCPT` with clever timeout, retry and reconnect functionality.

Some SMTP server take a long time for initial communication (banner and greeting) and then
handle subsequent commands quite fast. Then again they randomly start to get slow again.

This implementation of SMTP user enumeration counteracts with granular timeout, retry and
reconnect options for initial communication and enumeration separately.
The defaults should work fine, however if you encounter slow enumeration, adjust the settings
according to your needs.

Additionally if it encounters anything like `421 Too many errors on this connection` it will
automatically and transparently reconnect and continue from where it left off.


> Inspired by [smtp-user-enum](http://pentestmonkey.net/tools/user-enumeration/smtp-user-enum) Perl script and rewritten in Python with full Python2 and Python3 support.


## Installation
```bash
pip install smtp-user-enum
```


## Usage

```bash
$ smtp-user-enum --help

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
                        Supported modes: VRFY, EXPN, RCPT
                        Default: VRFY
  -d addr, --domain addr
                        Domain to append to users to convert into email addresses.
                        Useful of you see this response: '550 A valid address is required'
                        Default: Nothing appended
  -f addr, --from-mail addr
                        MAIL FROM email address. Only used in RCPT mode
                        Default: user@example.com
  -u user, --user user  Username to test.
  -U file, --file file  Newline separated wordlist of users to test.
  -V, --verbose         Show verbose output. Useful to adjust your timing and retry settings.
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

## RCPT mode

### Successful RCPT mode output

```bash
$ smtp-user-enum -m RCPT -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 user@example.com... Sender ok
Start enumerating users with RCPT mode ...
[----] OutOfBox          550 5.1.1 OutOfBox... User unknown
[SUCC] root              250 2.1.5 root... Recipient ok
[SUCC] adm               250 2.1.5 adm... Recipient ok
[----] admin             550 5.1.1 admin... User unknown
[----] administrator     550 5.1.1 administrator... User unknown
[----] backup            550 5.1.1 backup... User unknown
[----] bbs               550 5.1.1 bbs... User unknown
[SUCC] bin               250 2.1.5 bin... Recipient ok
[----] checkfs           550 5.1.1 checkfs... User unknown
[----] checksys          550 5.1.1 checksys... User unknown
```

### Troubleshooting EXPN mode

```bash
$ smtp-user-enum -m RCPT -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 user@example.com... Sender ok
Start enumerating users with RCPT mode ...
[----] 4Dgifts           550 A valid address is required.
[----] EZsetup           550 A valid address is required.
[----] OutOfBox          550 A valid address is required.
[----] root              550 A valid address is required.
[----] adm               550 A valid address is required.
```

By the above output you can see that pure usernames are not allowed to be specified,
this can be counteracted with the `-d` command, to append a domain to each username during enumeration:

```bash
$ smtp-user-enum -m RCPT -d 'example.com' -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 user@example.com... Sender ok
Start enumerating users with RCPT mode ...
[----] 4Dgifts           450 4.7.1 4Dgifts@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.11.0.226
[----] EZsetup           450 4.7.1 EZsetup@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.11.0.226
[----] OutOfBox          450 4.7.1 OutOfBox@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.11.0.226
[----] root              450 4.7.1 root@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.11.0.226
[----] adm               450 4.7.1 adm@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.11.0.226
```

Looks like the server is also hardened against relaying. To circumvent this, you could try to specify the server's hostname (cann be seen in the banner or greeting) or use `127.0.0.1` as the domain for users:

```bash
$ smtp-user-enum -m RCPT -d '127.0.0.1' -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 user@example.com... Sender ok
Start enumerating users with RCPT mode ...
[SUCC] 4Dgifts           250 2.1.5 4Dgifts@127.0.0.1... Recipient ok (will queue)
[SUCC] EZsetup           250 2.1.5 EZsetup@127.0.0.1... Recipient ok (will queue)
[SUCC] OutOfBox          250 2.1.5 OutOfBox@127.0.0.1... Recipient ok (will queue)
[SUCC] root              250 2.1.5 root@127.0.0.1... Recipient ok (will queue)
[SUCC] adm               250 2.1.5 adm@127.0.0.1... Recipient ok (will queue)
[SUCC] admin             250 2.1.5 admin@127.0.0.1... Recipient ok (will queue)
[SUCC] administrator     250 2.1.5 administrator@127.0.0.1... Recipient ok (will queue)
[SUCC] anon              250 2.1.5 anon@127.0.0.1... Recipient ok (will queue)
[SUCC] auditor           250 2.1.5 auditor@127.0.0.1... Recipient ok (will queue)
[SUCC] backup            250 2.1.5 backup@127.0.0.1... Recipient ok (will queue)
```

Looks like `127.0.0.1` as the user's domain leads to false positives, let's try the exact domain speified in the banner `mail.example.tld`:

```bash
$ smtp-user-enum -m RCPT -d '127.0.0.1' -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 user@example.com... Sender ok
Start enumerating users with RCPT mode ...
[----] 4Dgifts           550 5.1.1 4Dgifts@mail.example.tld... User unknown
[----] EZsetup           550 5.1.1 EZsetup@mail.example.tld... User unknown
[----] OutOfBox          550 5.1.1 OutOfBox@mail.example.tld... User unknown
[SUCC] ROOT              250 2.1.5 ROOT@mail.example.tld... Recipient ok
[SUCC] adm               250 2.1.5 adm@mail.example.tld... Recipient ok
[----] admin             550 5.1.1 admin@mail.example.tld... User unknown
[----] administrator     550 5.1.1 administrator@mail.example.tld... User unknown
[----] anon              550 5.1.1 anon@mail.example.tld... User unknown
[----] auditor           550 5.1.1 auditor@mail.example.tld... User unknown
[----] avahi             550 5.1.1 avahi@mail.example.tld... User unknown
[----] avahi-autoipd     550 5.1.1 avahi-autoipd@mail.example.tld... User unknown
[----] backup            550 5.1.1 backup@mail.example.tld... User unknown
[----] bbs               550 5.1.1 bbs@mail.example.tld... User unknown
[SUCC] bin               250 2.1.5 bin@mail.example.tld... Recipient ok
[----] checkfs           550 5.1.1 checkfs@mail.example.tld... User unknown
```


## Disclaimer

This tool may be used for legal purposes only. Users take full responsibility for any actions performed using this tool. The author accepts no liability for damage caused by this tool. If these terms are not acceptable to you, then do not use this tool.


## License

**[MIT License](LICENSE.txt)**

Copyright (c) 2020 **[cytopia](https://github.com/cytopia)**
