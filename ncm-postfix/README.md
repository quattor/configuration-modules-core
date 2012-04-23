# Postfix NCM component for Quattor

## Introduction

This is an NCM component that configures
[Postfix](http://www.postfix.org) with
[Quattor](http://www.quattor.org).

See the POD files for full documentation.

## Status

It is still quite incomplete. It requires:

* A forked version of ncm-ncd (that will become mainstream eventually)
* A special version of the build tools that should be able to run
  tests locally, without root intervention.
* More documentation.

## What it currently does:

* Generates correctly `main.cf` and `master.cf`
* Configures correctly LDAP databases.
