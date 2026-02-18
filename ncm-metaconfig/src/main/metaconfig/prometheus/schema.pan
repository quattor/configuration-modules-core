declaration template metaconfig/prometheus/schema;

include 'pan/types';

type prometheus_duration = string with match(
    SELF,
    '((([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?|0)'
);
type prometheus_tls_client_auth = choice(
    'NoClientCert',
    'RequestClientCert',
    'RequireAnyClientCert',
    'VerifyClientCertIfGiven',
    'RequireAndVerifyClientCert'
);
type prometheus_tls_version = choice('TLS10', 'TLS11', 'TLS12', 'TLS13');
type prometheus_scheme = choice('http', 'https');
type prometheus_relabel_action = choice(
    'replace',
    'lowercase',
    'uppercase',
    'keep',
    'drop',
    'hashmod',
    'labelmap',
    'labeldrop',
    'labelkeep'
);

type prometheus_global = {
    'scrape_interval' : prometheus_duration = '1m'
    'scrape_timeout' : prometheus_duration = '10s'
    'evaluation_interval' : prometheus_duration = "1m"
};

type prometheus_tls_server_config = {
    'cert_file': absolute_file_path
    'key_file': absolute_file_path
    'client_auth_type' ? prometheus_tls_client_auth = "NoClientCert"
    'client_ca_file' ? absolute_file_path
    'min_version' ? prometheus_tls_version = "TLS12"
    'max_version' ? prometheus_tls_version = "TLS13"
};

type prometheus_tls_config = {
    'ca_file' ? absolute_file_path
    'cert_file' ? absolute_file_path
    'key_file' ? absolute_file_path
    'server_name' ? string
    'insecure_skip_verify' ? boolean
    'min_version' ? prometheus_tls_version
};

type prometheus_relabel_config = {
    'source_labels' ? string[]
    'separator' ? string = ";"
    'target_label' ? string
    'regex' ? string = "(.*)"
    'modulus' ? long(0..)
    'replacement' ? string = "$1"
    'action' ?  prometheus_relabel_action
};

type prometheus_file_sd_config = {
    'files' : string[]
};

type prometheus_scrape_config_params = {
    'collect' ? string[]
    'module' ? string[]
};

type prometheus_scrape_config = {
    'job_name' : string
    'scrape_interval' ? prometheus_duration
    'scrape_timeout' ? prometheus_duration
    'metrics_path' ? type_URI
    'honor_labels' ? boolean
    'honor_timestamps' ? boolean
    'scheme' ? prometheus_scheme
    'params' ? prometheus_scrape_config_params
    'follow_redirects' ? boolean
    'enable_http2' ? boolean
    'tls_config' ? prometheus_tls_config
    'proxy_url' ? string
    'static_configs' ? absolute_file_path[]
    'sample_limit' ? long(0..)
    'label_limit' ? long(0..)
    'label_name_length_limit' ? long(0..)
    'label_value_length_limit' ? long(0..)
    'target_limit' ? long(0..)
    'file_sd_configs' ? prometheus_file_sd_config[]
    'relabel_configs' ? prometheus_relabel_config[]
    'metric_relabel_configs' ? prometheus_relabel_config[]
};

type prometheus_basic_auth = {
    'username' : string
    'password' ? string
    'password_file' ? absolute_file_path
};

type prometheus_authorization = {
    'type' : string = 'Bearer'
    'credentials' ? string
    'credentials_file' ? absolute_file_path
};

type prometheus_static_config = {
    'targets' : string[]
    'labels' ? dict()
};


type prometheus_alertmanager = {
    'timeout' ? prometheus_duration
    'api_version'? string
    'path_prefix' ? string
    'scheme' ? prometheus_scheme
    'basic_auth' ? prometheus_basic_auth
    'authorization' ? prometheus_authorization
    'tls_config' ? prometheus_tls_config
    'proxy_url' ? string
    'follow_redirects' ? boolean
    'enable_http2' ? boolean
    'file_sd_configs' ? prometheus_file_sd_config[]
    'static_configs' ? prometheus_static_config[]
    'relabel_configs' ? prometheus_relabel_config[]
};
type prometheus_alerting = {
    'alertmanagers': prometheus_alertmanager[]
    'alert_relabel_configs' ? prometheus_relabel_config[]
};

type prometheus_server_config = {
    'global': prometheus_global
    'tls_server_config' ? prometheus_tls_server_config
    'scrape_configs' ? prometheus_scrape_config[] = list()
    'rule_files' ? absolute_file_path[]
    'alerting' ? prometheus_alerting
};

type prometheus_rule = {
    'alert' : string
    'expr' : string
    'for' ? prometheus_duration
    'labels' ? dict()
    'annotations' ? dict()
};

type prometheus_rules_group = {
    'name' : string
    'rules' : prometheus_rule[]
    'interval' ? prometheus_duration
    'limit' ? long(0..)
};

type prometheus_rules_config = {
    'groups' ? prometheus_rules_group[]
};

type alertmanager_global = {
    'smtp_from' : string
    'smtp_smarthost' : string
    'smtp_hello' ? string
    'smtp_auth_username' ? string
    'smtp_auth_password' ? string
    'smtp_auth_identity' ? string
    'smtp_auth_secret' ? string
    'smtp_require_tls' ? boolean
    'slack_api_url' ? string
    'slack_api_url_file' ? absolute_file_path
    'victorops_api_key' ? string
    'victorops_api_url' ? string
    'pagerduty_url' ? string
    'opsgenie_api_key' ? string
    'opsgenie_api_key_file' ? absolute_file_path
    'opsgenie_api_url' ? string
    'wechat_api_url' ? string
    'wechat_api_secret' ? string
    'wechat_api_corp_id' ? string
    'telegram_api_url' ? string
    'resolve_timeout' ? prometheus_duration
};

type alertmanager_email_config = {
    'send_resolved' ? boolean
    'to' : type_email
    'from' : type_email
    'smarthost' ? string
    'hello' ? string
    'auth_username' ? string
    'auth_password' ? string
    'auth_secret' ? string
    'auth_identity' ? string
    'require_tls' ? boolean
    'tls_config' ? prometheus_tls_config
    'html' ? string
    'text' ? string
    'headers' ? dict()
};

type alertmanager_slack_config = {
    'send_resolved' ? boolean
    'api_url' ? string
    'api_url_file' ? absolute_file_path
    'channel' : string
    'icon_emoji' ? string
    'icon_url' ? string
    'link_names' ? boolean
    'username' ? string
    'text' ? string
    'title' ? string
    'title_link' ? string
    'image_url' ? string
    'thumb_url' ? string
};

type alertmanager_webhook_config = {
    'send_resolved' ? boolean
    'url': type_absoluteURI
    'max_alerts' ? long(0..)
};

type alertmanager_receiver = {
    'name' : string
    'email_configs' ? alertmanager_email_config[]
    'slack_configs' ? alertmanager_slack_config[]
    'webhook_configs' ? alertmanager_webhook_config[]
};

type alertmanager_route = {
    'receiver' ? string
    'group_by' ? string[]
    'continue' ? boolean
    'matchers' ? dict
    'group_wait' ? prometheus_duration
    'group_interval' ? prometheus_duration
    'repeat_interval' ? prometheus_duration
    'mute_time_intervals' ? string[]
    'active_time_intervals' ? string[]
};

type alertmanager_root_route = {
    'receiver' ? string
    'group_by' ? string[]
    'continue' ? boolean
    'matchers' ? dict
    'group_wait' ? prometheus_duration
    'group_interval' ? prometheus_duration
    'repeat_interval' ? prometheus_duration
    'routes' ? alertmanager_route[]
};

type alertmanager_inhibit_rule = {
    'target_matchers' : string[]
    'source_matchers' : string[]
    'equal': string[]
};

type alertmanager_time_range = {
    'start_time' : string
    'end_time': string
};

type alertmanager_time_interval_def = {
    'times' ? alertmanager_time_range[]
    'weekdays' ? string[]
    'days_of_month' ? string[]
    'months' ? string[]
    'years' ? string[]
};

type alertmanager_time_interval = {
    'name' : string
    'time_intervals' : alertmanager_time_interval_def[]
};

type alertmanager_server_config = {
    'global' : alertmanager_global
    'templates' ? absolute_file_path[]
    'route' : alertmanager_root_route = dict()
    'receivers' : alertmanager_receiver[]
    'inhibit_rules' ? alertmanager_inhibit_rule[]
    'time_intervals' ? alertmanager_time_interval[]
};
