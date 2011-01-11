COMP=accounts
NAME=ncm-$(COMP)
DESCR=accounts NCM component.
VERSION=5.1.2
RELEASE=1
AUTHOR=Luis Fernando Muñoz Mejías <Luis.Fernando.Munoz.Mejias@cern.ch>, Charles Loomis <charles.loomis@cern.ch>, Stephen Childs <childss@cs.tcd.ie>
MAINTAINER=Luis Fernando Muñoz Mejías <Luis.Fernando.Munoz.Mejias@cern.ch>

CCONFIGDIR=$(NCM_CONF)/$(COMP)
CONFIGFILE=$(CONFIGDIR)/config

NCM_EXTRA_REQUIRES=libuser

TESTVARS=

MANSECT=8
MANDIR=

DATE=11/01/11 17:27
