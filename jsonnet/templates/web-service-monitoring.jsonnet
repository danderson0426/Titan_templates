// Example: Basic web service monitoring template
local prometheus = import '../lib/prometheus.libsonnet';
local utils = import '../lib/utils.libsonnet';

// Configuration
local config = {
  service_name: 'web-service',
  environment: 'production',
  namespace: 'default',
  team: 'backend',
};

// Alert rules for a web service
local alertRules = [
  // High error rate
  prometheus.alerts.highErrorRate(
    config.service_name + '_high_error_rate',
    'http_requests_total',
    threshold=0.05,  // 5% error rate
    duration='5m',
    filters={
      job: config.service_name,
      code: '~"5.."',
    }
  ),

  // High latency (95th percentile)
  prometheus.alerts.highLatency(
    config.service_name + '_high_latency',
    'http_request_duration_seconds_bucket',
    threshold=1.0,  // 1 second
    duration='5m',
    filters={
      job: config.service_name,
    }
  ),

  // Service availability
  prometheus.alerts.serviceDown(
    config.service_name + '_down',
    metric='up',
    duration='1m',
    filters={
      job: config.service_name,
    }
  ),

  // High memory usage
  {
    alert: config.service_name + '_high_memory',
    expr: 'process_resident_memory_bytes{job="' + config.service_name + '"} / 1024 / 1024 > 500',
    'for': '5m',
    labels: utils.labels.standard(config.service_name + '_memory') + {
      severity: 'warning',
      type: 'resource',
    },
    annotations: {
      summary: 'High memory usage',
      description: 'Memory usage is {{ $value }}MB for {{ $labels.instance }}',
    },
  },

  // High CPU usage
  {
    alert: config.service_name + '_high_cpu',
    expr: 'rate(process_cpu_seconds_total{job="' + config.service_name + '"}[5m]) * 100 > 80',
    'for': '5m',
    labels: utils.labels.standard(config.service_name + '_cpu') + {
      severity: 'warning',
      type: 'resource',
    },
    annotations: {
      summary: 'High CPU usage',
      description: 'CPU usage is {{ $value }}% for {{ $labels.instance }}',
    },
  },
];

// Recording rules for SLIs
local recordingRules = [
  // Request rate
  prometheus.recordings.rule(
    config.service_name + ':request_rate',
    'sum(rate(http_requests_total{job="' + config.service_name + '"}[5m]))',
    utils.labels.standard(config.service_name + '_request_rate')
  ),

  // Error rate
  prometheus.recordings.rule(
    config.service_name + ':error_rate',
    'sum(rate(http_requests_total{job="' + config.service_name + '",code=~"5.."}[5m])) / sum(rate(http_requests_total{job="' + config.service_name + '"}[5m]))',
    utils.labels.standard(config.service_name + '_error_rate')
  ),

  // Availability SLI
  prometheus.recordings.sli.availability(
    config.service_name,
    'sum(rate(http_requests_total{job="' + config.service_name + '",code!~"5.."}[5m]))',
    'sum(rate(http_requests_total{job="' + config.service_name + '"}[5m]))',
    { service: config.service_name }
  ),
];

// Generate PrometheusRule resource
prometheus.prometheusRule(
  config.service_name + '-monitoring',
  config.namespace,
  [
    {
      name: config.service_name + '-alerts',
      interval: '30s',
      rules: alertRules,
    },
    {
      name: config.service_name + '-recordings',
      interval: '30s', 
      rules: recordingRules,
    },
  ]
)