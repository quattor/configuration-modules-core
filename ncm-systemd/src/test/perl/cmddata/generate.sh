#!/bin/bash

# pass a unique name as first argument
reason=gen_${1:-X}

fn=service_systemctl_list_show_$reason
fnload=${fn}_load
rm -f $fn $fnload.pm

function begin_load () {
    # load it in the cmddata module
    # use this module in a .t file

    echo "package cmddata::$fnload;" >> $fnload.pm
    echo "use helper;" >> $fnload.pm
    echo >> $fnload.pm
}

function end_load () {
    echo "1;" >> $fnload.pm
    echo "Created $fn $fnload.pm"
}

function add () {
    name="$1"
    cmd="$2"
    ec="$3"
    out="$4"

    all="$all $name"
    echo "\$cmds{'$name'}{cmd} = '$cmd';">>$fn
    echo "\$cmds{'$name'}{ec} = $ec;">>$fn
    echo "\$cmds{'$name'}{out} = <<'EOF';">>$fn
    echo "$out" >> $fn
    echo EOF >> $fn 
    echo >> $fn

    # add to the load file
    echo "set_output('$name');" >> $fnload.pm

}

begin_load

for list in unit-files units; do
    cmd="/usr/bin/systemctl --all --no-pager --no-legend --full list-$list"
    name="${reason}_systemctl_list-${list}"

    out=`$cmd`
    add "$name" "$cmd" $? "$out"

    for unit in `echo "$out" |sed -e "s/\s\+.*$//;"`; do

        # These might not be unique wrt list-unit and list-unit-files
        # but should show same info

        name="${reason}_systemctl_show_${unit}_${list}"
        cmd="/usr/bin/systemctl --no-pager --all show -- $unit"
        echo "unit $unit name $name command $cmd"
        out=`$cmd`
        add "$name" "$cmd" $? "$out"

        name="${reason}_systemctl_list_dependencies_${unit}_${list}"
        cmd="/usr/bin/systemctl --no-pager --no-legend --full --plain list-dependencies -- $unit"
        echo "unit $unit name $name command $cmd"
        out=`$cmd`
        add "$name" "$cmd" $? "$out"

        name="${reason}_systemctl_list_dependencies_reverse_${unit}_${list}"
        cmd="/usr/bin/systemctl --no-pager --no-legend --full --plain list-dependencies --reverse -- $unit"
        echo "unit $unit name $name command $cmd"
        out=`$cmd`
        add "$name" "$cmd" $? "$out"

        name="${reason}_systemctl_is_enabled_${unit}_${list}"
        cmd="/usr/bin/systemctl is-enabled -- $unit"
        echo "unit $unit name $name command $cmd"
        out=`$cmd`
        add "$name" "$cmd" $? "$out"

        name="${reason}_systemctl_is_active_${unit}_${list}"
        cmd="/usr/bin/systemctl is-active -- $unit"
        echo "unit $unit name $name command $cmd"
        out=`$cmd`
        add "$name" "$cmd" $? "$out"

    done            
done

end_load
