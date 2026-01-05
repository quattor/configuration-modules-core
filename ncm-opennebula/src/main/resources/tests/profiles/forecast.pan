object template forecast;

include 'components/opennebula/schema';

bind "/metaconfig/contents" = opennebula_forecast;

"/metaconfig/module" = "yaml";

prefix "/metaconfig/contents";
"host" = dict(
    "db_retention", 4,
    "forecast", dict(
        "enabled", true,
        "period", 5,
        "lookback", 60,
    ),
    "forecast_far", dict(
        "enabled", true,
        "period", 43200,
        "lookback", 86400,
    ),
);
"virtualmachine" = dict(
    "db_retention", 2,
    "forecast", dict(
        "enabled", true,
        "period", 5,
        "lookback", 60,
    ),
    "forecast_far", dict(
        "enabled", true,
        "period", 2880,
        "lookback", 10080,
    ),
);
