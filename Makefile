####################################################################
# Distribution Makefile for NCM components *only*
####################################################################
#
# copy this file to your component's directory as 'Makefile'
#
# BTDIR needs to point to the location of the build tools. Try to be smart here:
# the needed part can be in some parent directory.
#
_qbt_dir	:= quattor-build-tools
BTDIR		:= $(shell \
	ls -d $(_qbt_dir) 2>/dev/null || \
	ls -d ../$(_qbt_dir) 2>/dev/null || \
	ls -d ../../$(_qbt_dir) 2>/dev/null || \
	ls -d ../../../$(_qbt_dir) 2>/dev/null || \
	ls -d ../../../../$(_qbt_dir) 2>/dev/null || \
	echo $(_qbt_dir))
#
#
_btincl		:= $(shell ls $(BTDIR)/quattor-component.mk 2>/dev/null || \
	echo quattor-component.mk)
include $(_btincl)
