object template fastestmirror;

include 'base';

# everything else has schema defaults
prefix '/software/components/spma/plugins/fastestmirror';
'enabled' = true;
'exclude' = list("*.something", "more.more");
'include_only' = list("me.too", "even.more");
