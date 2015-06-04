### NAME

NCM::sendmail - NCM Sendmail configuration component

### SYNOPSIS

- Configure()
    - -

        Set From header masquerading in sendmail.
        i.e. change the From field "username@localhost.localdomain" to "username@mail.cern.ch".
        Use the following input `/software/components/sendmail/userdomain`

    - -

        Set Return-Path masquerading in sendmail.
        i.e. change the Return-Path header "username@localhost.localdomain" to "username@mail.cern.ch".

    - -

        Set the outgoing mail server ("smarthost") in sendmail.
        Use the following input `/software/components/sendmail/smarthost`

    - -

        Allow external SMTP connections. By default sendmail will listen only to the loopback interface.

    - -

        Sets up "relay" for all unqualified names, except either for the list in
        `/software/components/sendmail/localusers` or, if that list hasn't been configured,
        for a (guessed) list of accounts that

        - have an existing home directory
        - do **not** have an AFS home directory (`/afs/...`)
        - do not already have an alias definition in `/etc/mail/aliases.db`.
        - whose _uid_ indicates that this is not a system account (information from `/etc/login.defs`)

        "relay" means that a local _mail username_ command on the machine
        will in reality send mail to username@mail.server.dom, instead of
        being appended to the user's local mailbox
        (e.g. _/var/spool/mail/username_).

        To turn off the "guessing" mechanism, you will have to configure at
        least one account in `/software/components/sendmail/localusers`,
        `root` is a good candidate.
- Unconfigure()
- - Reset From header masquerading in sendmail.
- - Reset Return-Path header masquerading in sendmail.
- - Reset outgoing mail server in sendmail.
- - Reset relay all unqualified names in sendmail.

### RESOURCES

- `/etc/mail/sendmail.mc` : sendmail macro configuration file
- `/etc/mail/semdmail.cf` : sendmail configuration file

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### BUGS

The "local user relay" functionality seems to interfere with user
.forward files, they may not be honoured on some sendmail versions.

Selectively "unconfiguring" certain elements doesn't work, you should
run the _unconfigure()_ method and re-_configure()_ with the new
values afterwards.

Jan Iven <>

### SEE ALSO

ncm-ncd(1), sendmail(8)
