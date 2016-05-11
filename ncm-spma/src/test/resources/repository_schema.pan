# Profile to validate all valid characters in a repository name

object template repository_schema;

include "components/spma/schema";

'/software/components/spma' = dict();
'/software/packages' = dict();
'/software/groups' = dict();

prefix "/software/repositories/0";

"name" = "test-repository_v2.x";
"owner" = "me@example.com";
"protocols/0/name" = "http";
"protocols/0/url" = "http://www.example.com";


