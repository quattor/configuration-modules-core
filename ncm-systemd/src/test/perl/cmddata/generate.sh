#!/bin/bash

# pass a unique name as first argument
reason=gen_${1:-X}

fn=service_systemctl_list_show_$reason
fnload=${fn}_load
all=""
rm -f $fn $fnload.pm
for type in target service; do 
  cmd="/usr/bin/systemctl list-unit-files --all --no-pager --no-legend --type $type"
  name="${reason}_systemctl_list_unit_files_$type"
  all="$all $name"
  echo "\$cmds{$name}{cmd} = \"$cmd\";">>$fn
  echo "\$cmds{$name}{out} = <<'EOF';">>$fn
  $cmd >> $fn
  echo EOF >> $fn 
  echo >> $fn
  for unit in `$cmd |sed -e "s/\@\?\.[^.]*\s\+.*$//;"`; do
    name=`echo "${reason}_systemctl_show_${unit}_${type}_el7" | tr '-' '_' | tr '.' '_'`
    all="$all $name"
    cmd="/usr/bin/systemctl --no-pager --all show $unit.$type"
    echo "\$cmds{$name}{cmd} = \"$cmd\";">>$fn
    echo "\$cmds{$name}{out} = <<'EOF';">>$fn
    $cmd >> $fn
    echo EOF >> $fn 
    echo >> $fn
  done
done

# load it in the cmddata module
# use this module in a .t file

echo "package cmddata::$fnload;" >> $fnload.pm
echo "use helper;" >> $fnload.pm
echo >> $fnload.pm
for i in $all; do
  echo "set_output('$i');" >> $fnload.pm
done
echo "1;" >> $fnload.pm

echo "Created $fn $fnload.pm"
