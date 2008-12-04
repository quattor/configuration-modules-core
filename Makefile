####################################################################
# Distribution Makefile
####################################################################

#
# BTDIR needs to point to the location of the build tools
#
BTDIR := ../../../quattor-build-tools
#
#
_btincl   := $(shell ls $(BTDIR)/quattor-component.mk 2>/dev/null || \
             echo quattor-component.mk)
include $(_btincl)



