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

**Table of contents**

1. [Installation](#installation)
2. [Features](#features)
3. [Usage](#usage)
4. [VRFY mode (default)](#vrfy-mode-default)
    1. [How does VRFY work](#how-does-vrfy-work)
    2. [Successful VRFY enumeration](#successful-vrfy-enumeration)
    3. [Failed VRFY enumeration](#failed-vrfy-enumeration)
5. [EXPN mode](#expn-mode)
    1. [How does EXPN work](#how-does-expn-work)
    2. [Successful EXPN enumeration](#successful-expn-enumeration)
    3. [Failed EXPN enumeration](#failed-expn-enumeration)
6. [RCPT mode](#rcpt-mode)
    1. [How does RCPT work](#how-does-rcpt-work)
    2. [Successful RCPT enumeration](#successful-rcpt-enumeration)
    3. [Troubleshooting EXPN enumeration](#troubleshooting-expn-enumeration)
        1. [550 A valid address is required](#550-a-valid-address-is-required)
        2. [450 Relaying temporarily denied](#450-relaying-temporarily-denied)
        3. [False positives](#false-positives)
        4. [Investigating timeouts](#investigating-timeouts)
7. [Mitigation](#mitigation)
    1. [VRFY and EXPN](#vrfy-and-expn)
        1. [Postfix](#postfix)
        2. [Sendmail](#sendmail)
        3. [Exim](#exim)
    2. [RCPT TO](#rcpt-to)
8. [Disclaimer](#disclaimer)
9. [License](#license)


## Installation
```bash
pip install smtp-user-enum
```


## Features

* Enumerate users via `VRFY`, `EXPN` or `RCPT`
* Find out which users are aliases via `RCPT`
* Fully customize from email for `RCPT` mode
* Append domains to usernames
* Wrap usernames or emails in `<` and `>`
* Very verbose mode
* Very granular timing, retry and reconnect options for all phases
* Works with Python2 and Python3

See troubleshooting section for examples on how to use different options


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
                        Supported modes: VRFY, EXPN, RCPT
                        Default: VRFY
  -d addr, --domain addr
                        Domain to append to users to convert into email addresses.
                        Useful if you see this response: '550 A valid address is required'
                        Default: Nothing appended
  -w, --wrap            Wrap the username or email address in '<' and '>' characters.
                        Usefule if you see this response: '501 5.5.2 Syntax error in parameters or arguments'.
                        Makes sense to combine with -d/--domain option.
                        Default: Nothing wrapped
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

### How does VRFY work

The `VRFY` mode can easily be tested with `nc` or `telnet` as shown below:
```bash
$ nc mail.example.tld 25
```
```
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Thu, 23 Jan 2020 16:03:22 +0200
HELO test
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
VRFY someuser
550 5.1.1 someuser... User unknown
VRFY bob
250 2.1.5 <bob@mail.example.tld>
```

As can be seen `VRFY someuser` tells us it does not exist whereas `VRFY bob` yields a positive result.

### Successful VRFY enumeration

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

### Failed VRFY enumeration

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

### How does EXPN work

The `EXPN` mode can easily be tested with `nc` or `telnet` as shown below:
```bash
$ nc mail.example.tld 25
```
```
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Thu, 23 Jan 2020 16:03:22 +0200
HELO test
250 mail.example.tld [10.0.0.1], pleased to meet you
EXPN someuser
550 5.1.1 someuser... User unknown
EXPN bob
250 2.1.5 <bob@mail.example.tld>
EXPN bin
250 2.1.5 root <root@mail.example.tld>
```

As can be seen `EXPN someuser` tells us it does not exist whereas `EXPN bob` and `EXPN bin` yield positive results. You can also see from the output that `bob` is a real user on the system, whereas
`bin` is just an alias pointing to `root`.

### Successful EXPN enumeration

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

### Failed EXPN enumeration

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

This is usually the most useful command to fish for usernames as `VRFY` and `EXPN` are often disabled.

### How does RCPT work

The `RCPT` mode can easily be tested with `nc` or `telnet` as shown below:
```bash
$ nc mail.example.tld 25
```
```
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Thu, 23 Jan 2020 16:03:22 +0200
HELO test
250 mail.example.tld [10.0.0.1], pleased to meet you
MAIL FROM:user@example.com
250 2.1.0 user@example.com... Sender ok
RCPT TO:someuser
550 5.1.1 someuser... User unknown
RCPT TO:bob
250 2.1.5 bob... Recipient ok
```

As can be seen `RCPT TO: someuser` tells us it does not exist whereas `RCPT TO: bob` yields a positive result.


### Successful RCPT enumeration

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

### Troubleshooting EXPN enumeration

#### 550 A valid address is required
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

#### 450 Relaying temporarily denied
```bash
$ smtp-user-enum -m RCPT -d 'example.com' -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 user@example.com... Sender ok
Start enumerating users with RCPT mode ...
[----] 4Dgifts           450 4.7.1 4Dgifts@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.0.0.1
[----] EZsetup           450 4.7.1 EZsetup@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.0.0.1
[----] OutOfBox          450 4.7.1 OutOfBox@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.0.0.1
[----] root              450 4.7.1 root@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.0.0.1
[----] adm               450 4.7.1 adm@example.com... Relaying temporarily denied. Cannot resolve PTR record for 10.0.0.1
```

Looks like the server is also hardened against relaying. To circumvent this, you could try to specify the server's hostname (cann be seen in the banner or greeting) or use `127.0.0.1` as the domain for users:

#### False positives
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

#### Investigating timeouts
```bash
$ smtp-user-enum -m RCPT -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
timed out
```

Let's add the `-V` to get some verbosity:

```bash
$ smtp-user-enum -V -m RCPT -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25
Connecting to mail.example.tld 25 ...
[1/4] Connecting to mail.example.tld:25 ...
[1/4] Waiting for banner ...
220 beta SMTP Server (JAMES SMTP Server 2.3.2) ready Wed, 22 Jan 2020 16:10:10 -0500 (EST)
[1/4] Sending greeting: HELO test
[1/4] Waiting for greeting reply ...
250 beta Hello test (10.0.0.1 [10.0.0.1])
[1/4] Sending: MAIL FROM: user@example.com
[1/4] Waiting for MAIL FROM reply ...
501 5.1.7 Syntax error in MAIL command
[2/4] Waiting for MAIL FROM reply ...
[3/4] Waiting for MAIL FROM reply ...
[4/4] Waiting for MAIL FROM reply ...
timed out
```

So apparently the mailserver does not like our command: `MAIL FROM: user@example.com`.
To circumvent this, let's put the from email in brackets like so: `MAIL FROM: <user@example.com>` via the `-f` argument:


```bash
$ smtp-user-enum -f '<user@example.com>' -m RCPT -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 Sender <user@example.com> OK
Start enumerating users with RCPT mode ...
[----] 4Dgifts           501 5.5.2 Syntax error in parameters or arguments
[----] EZsetup           501 5.5.2 Syntax error in parameters or arguments
[----] OutOfBox          501 5.5.2 Syntax error in parameters or arguments
[----] root              501 5.5.2 Syntax error in parameters or arguments
```

Looks like the usernames also need to be wrapped in `<` and `>` to satisfy this specific mailserver. To do this, simply add the `-w` option:

```bash
$ smtp-user-enum -w -f '<user@example.com>' -m RCPT -U /usr/share/wordlists/metasploit/unix_users.txt mail.example.tld 25

Connecting to mail.example.tld 25 ...
220 mail.example.tld ESMTP Sendmail 8.12.8/8.12.8; Wed, 22 Jan 2020 19:33:07 +0200
250 mail.example.tld Hello [10.0.0.1], pleased to meet you
250 2.1.0 Sender <user@example.com> OK
Start enumerating users with RCPT mode ...
[SUCC] 4Dgifts           250 2.1.5 Recipient <4Dgifts@localhost> OK
[SUCC] EZsetup           250 2.1.5 Recipient <EZsetup@localhost> OK
[SUCC] OutOfBox          250 2.1.5 Recipient <OutOfBox@localhost> OK
[SUCC] root              250 2.1.5 Recipient <root@localhost> OK
[SUCC] adm               250 2.1.5 Recipient <adm@localhost> OK
[SUCC] admin             250 2.1.5 Recipient <admin@localhost> OK
[SUCC] administrator     250 2.1.5 Recipient <administrator@localhost> OK
[SUCC] anon              250 2.1.5 Recipient <anon@localhost> OK
[SUCC] auditor           250 2.1.5 Recipient <auditor@localhost> OK
```

Unfortunately this yields to false positives again as it seems to be an open relay.
However, lessons learned from this is to use the `-V` option in case of issues to troubleshoot what is going on.
Maybe the open relay is another vector to hunt down.


## Mitigation

Now that you've seen how easy it could be to enumerate usernames on systems, you should ensure that your servers are hardened against this technique.

### VRFY and EXPN

#### Postfix

On Postfix `VRFY` seems to be not disabled by default as shown by [their documentation](http://www.postfix.org/postconf.5.html#disable_vrfy_command). It also looks like Postfix did not implement the `EXPN` command, so only `VRFY` needs to be disabled.

`main.cf`:
```ini
disable_vrfy_command = yes
```

#### Sendmail

On Sendmail you will have to adjust the privacy settings and reload its configuration afterwards in order to disable `VRFY` and `EXPN`.

`sendmail.cf`:
```diff
- O PrivacyOptions=
+ O PrivacyOptions=noexpn novrfy
```
or
```diff
- O PrivacyOptions=
+ O PrivacyOptions=goaway
```

#### Exim

On Exim you should check if those values have already been disabled and then disable them accordingly. For the `EXPN` directive, ensure to either comment it out or set it to `localhost` only.

`exim.conf`:
```diff
- smtp_verify = true
+ smtp_verify = false

- smtp_expn_hosts = ...
+ smtp_expn_hosts = localhost
```

### RCPT TO

The `RCPT TO` command cannot be disabled without breaking a mail server. What you should do instead is to require authentication:

* [Postifx SASL](http://www.postfix.org/SASL_README.html)
* [Sendmail SASL](https://www.sendmail.org/~ca/email/auth.html)
* [Exim SASL](https://www.exim.org/exim-html-current/doc/html/spec_html/ch-the_cyrussasl_authenticator.html)


## Disclaimer

This tool may be used for legal purposes only. Users take full responsibility for any actions performed using this tool. The author accepts no liability for damage caused by this tool. If these terms are not acceptable to you, then do not use this tool.


## License

**[MIT License](LICENSE.txt)**

Copyright (c) 2020 **[cytopia](https://github.com/cytopia)**
