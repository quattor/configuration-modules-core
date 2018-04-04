#!/bin/bash
export QUATTOR_PERL5LIB=/usr/lib/perl:/root/perl5/lib/perl5/
function mvn_run {
    local unsetfn quatenv
    quatenv="PERL5LIB=${QUATTOR_PERL5LIB:-$PERL5LIB} QUATTOR_TEST_LOG_CMD_MISSING=1 QUATTOR_TEST_LOG_CMD=1 QUATTOR_TEST_LOG_DEBUGLEVEL=3"
    # make a subshell with all bashfunctions removed. maven can have issues with then via exporting with env.BASH_FUNC
    unsetfn=""
    for fn in `env |grep BASH_FUNC_ | grep -v grep | sed "s/(.*//; s/BASH_FUNC_//" |tr "\n" ' '`; do
        unsetfn="unset -f $fn; $unsetfn"
    done
    bash -c "$unsetfn $quatenv mvn $1"
}
function mvn_test {
    local extra
    if [ ! -z "$1" ]; then
       extra="-Dunittest=$1.t"
    fi
     mvn_run "clean test -Dprove.args=-v $extra"
}

function mvn_pack {
    mvn_run "clean package -Dprove.args=-v"
}
mvn_test
