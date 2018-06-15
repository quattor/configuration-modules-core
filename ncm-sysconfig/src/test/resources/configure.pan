object template configure;

include 'components/sysconfig/schema';

prefix '/software/components/sysconfig';

'files/examplefile/key1' = 'testvalue';
'files/examplefile/key2' = 'valuetest';

'files/examplefile/boot' = "/dev/sda";
'files/examplefile/OPTS' = '"$OPTS -a /proc/acpi/ac_adapter/*/state"';
'files/examplefile/words' = "'lots of words'";
'files/examplefile/internal1' = "quoting 'inside' a line";
'files/examplefile/internal2' = 'quoting "inside" a line';
'files/examplefile/array' = '(this is a bash array)';
