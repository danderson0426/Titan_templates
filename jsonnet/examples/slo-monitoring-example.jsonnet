// Example: Using the Titan Templates library to create custom monitoring
local prometheus = import '../lib/prometheus.libsonnet';
local grafana = import '../lib/grafana.libsonnet';
local utils = import '../lib/utils.libsonnet';

// Define your service configuration
local serviceConfig = {
  name: 'my-api-service',
  environment: 'production',
  team: 'backend-team',
  namespace: 'default',
  
  // SLOs (Service Level Objectives)
  slos: {
    availability: 99.9,  // 99.9% uptime
    error_rate: 0.1,     // Less than 0.1% error rate
    latency_p95: 500,    // 95th percentile latency under 500ms
  },
};

// Create alert rules based on SLOs
local alerts = [
  // Availability alert - fires when availability drops below SLO
  prometheus.alerts.serviceDown(
    serviceConfig.name + '_availability_slo_breach',
    duration='2m',  // Tighter than usual for SLO
    filters={ job: serviceConfig.name }
  ),
  
  // Error rate alert - fires when error rate exceeds SLO
  prometheus.alerts.highErrorRate(
    serviceConfig.name + '_error_rate_slo_breach', 
    'http_requests_total',
    threshold=serviceConfig.slos.error_rate / 100,
    duration='5m',
    filters={ 
      job: serviceConfig.name,
      code: '~"5.."'
    }
  ),
  
  // Latency alert - fires when P95 latency exceeds SLO
  prometheus.alerts.highLatency(
    serviceConfig.name + '_latency_slo_breach',
    'http_request_duration_seconds_bucket',
    threshold=serviceConfig.slos.latency_p95 / 1000,  // Convert ms to seconds
    duration='5m',
    filters={ job: serviceConfig.name }
  ),
];

// Create custom recording rules for SLI calculations
local sliRecordings = [
  // Availability SLI (successful requests / total requests)
  prometheus.recordings.rule(
    serviceConfig.name + ':availability_sli',
    |||
      (
        sum(rate(http_requests_total{job="%(service)s", code!~"5.."}[5m])) /
        sum(rate(http_requests_total{job="%(service)s"}[5m]))
      ) * 100
    ||| % { service: serviceConfig.name },
    utils.labels.standard(serviceConfig.name + '_availability_sli', serviceConfig.environment, serviceConfig.team)
  ),
  
  // Error rate SLI
  prometheus.recordings.rule(
    serviceConfig.name + ':error_rate_sli',
    |||
      (
        sum(rate(http_requests_total{job="%(service)s", code=~"5.."}[5m])) /
        sum(rate(http_requests_total{job="%(service)s"}[5m]))
      ) * 100
    ||| % { service: serviceConfig.name },
    utils.labels.standard(serviceConfig.name + '_error_rate_sli', serviceConfig.environment, serviceConfig.team)
  ),
  
  // Latency SLI (P95)
  prometheus.recordings.rule(
    serviceConfig.name + ':latency_p95_sli',
    |||
      histogram_quantile(0.95,
        sum(rate(http_request_duration_seconds_bucket{job="%(service)s"}[5m])) by (le)
      )
    ||| % { service: serviceConfig.name },
    utils.labels.standard(serviceConfig.name + '_latency_p95_sli', serviceConfig.environment, serviceConfig.team)
  ),
];

// Generate the PrometheusRule
local prometheusRule = prometheus.prometheusRule(
  serviceConfig.name + '-slo-monitoring',
  serviceConfig.namespace,
  [
    {
      name: serviceConfig.name + '-sli-recordings',
      interval: '30s',
      rules: sliRecordings,
    },
    {
      name: serviceConfig.name + '-slo-alerts',
      interval: '30s', 
      rules: alerts,
    },
  ]
);

// Create a custom Grafana dashboard using the library
local dashboard = grafana.dashboard(
  serviceConfig.name + ' SLO Dashboard',
  'Service Level Objectives monitoring for ' + serviceConfig.name,
  [serviceConfig.name, 'slo', 'monitoring'],
  [
    // SLO Overview panels
    grafana.panels.stat(
      'Availability SLI',
      [grafana.targets.prometheus(
        serviceConfig.name + ':availability_sli',
        'Current: {{value}}%'
      )],
      'percent',
      [serviceConfig.slos.availability - 1, serviceConfig.slos.availability - 0.1]
    ),
    
    grafana.panels.stat(
      'Error Rate SLI', 
      [grafana.targets.prometheus(
        serviceConfig.name + ':error_rate_sli',
        'Current: {{value}}%'
      )],
      'percent',
      [serviceConfig.slos.error_rate / 2, serviceConfig.slos.error_rate]
    ),
    
    grafana.panels.stat(
      'Latency P95 SLI',
      [grafana.targets.prometheus(
        serviceConfig.name + ':latency_p95_sli',
        'Current: {{value}}s'
      )],
      's',
      [serviceConfig.slos.latency_p95 / 1000 / 2, serviceConfig.slos.latency_p95 / 1000]
    ),
    
    // Trend charts
    grafana.panels.timeSeries(
      'Availability Trend',
      [grafana.targets.prometheus(
        serviceConfig.name + ':availability_sli',
        'Availability %'
      )],
      'percent'
    ),
    
    grafana.panels.timeSeries(
      'Error Rate Trend',
      [grafana.targets.prometheus(
        serviceConfig.name + ':error_rate_sli', 
        'Error Rate %'
      )],
      'percent'
    ),
    
    grafana.panels.timeSeries(
      'Latency P95 Trend',
      [grafana.targets.prometheus(
        serviceConfig.name + ':latency_p95_sli',
        'P95 Latency'
      )],
      's'
    ),
  ],
  time_from='now-24h'
);

// Output both the PrometheusRule and dashboard configuration
{
  prometheusRule: prometheusRule,
  grafanaDashboard: dashboard,
  
  // Helper: Generate YAML output for Kubernetes
  yaml: std.manifestYamlDoc(prometheusRule),
  
  // Helper: Generate JSON output for Grafana import
  json: std.manifestJsonEx(dashboard, '  '),
}