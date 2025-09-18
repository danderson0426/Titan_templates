// Template: Complete web service monitoring with Grafonnet-generated dashboards
// This template demonstrates the integration between Prometheus alerts and 
// Grafana dashboards using Grafonnet for a typical web service

local prometheus = import '../lib/prometheus.libsonnet';
local grafonnet = import '../lib/grafonnet.libsonnet';
local utils = import '../lib/utils.libsonnet';

// Template parameters - customize these for your service
local config = {
  service_name: 'REPLACE_WITH_SERVICE_NAME',
  environment: 'REPLACE_WITH_ENVIRONMENT',  // production, staging, development
  namespace: 'REPLACE_WITH_NAMESPACE',      // kubernetes namespace
  team: 'REPLACE_WITH_TEAM_NAME',

  // SLO targets (adjust based on your requirements)
  slos: {
    availability: 99.9,    // 99.9% availability target
    error_rate: 1.0,       // 1% error rate threshold  
    latency_p95: 500,      // 500ms P95 latency target
    latency_p99: 1000,     // 1000ms P99 latency target
  },

  // Alert thresholds
  thresholds: {
    error_rate: 0.05,      // 5% error rate alert threshold
    latency: 1.0,          // 1 second latency alert threshold
    memory_mb: 512,        // 512MB memory usage alert threshold
    cpu_percent: 80,       // 80% CPU usage alert threshold
  },
};

// Comprehensive alert rules
local alertRules = [
  // Service availability
  prometheus.alerts.serviceDown(
    config.service_name + '_down',
    metric='up',
    duration='1m',
    filters={ job: config.service_name }
  ),

  // Error rate monitoring
  prometheus.alerts.highErrorRate(
    config.service_name + '_high_error_rate',
    'http_requests_total',
    threshold=config.thresholds.error_rate,
    duration='5m',
    filters={ 
      job: config.service_name,
      code: '~"5.."' 
    }
  ),

  // Latency monitoring  
  prometheus.alerts.highLatency(
    config.service_name + '_high_latency',
    'http_request_duration_seconds_bucket',
    threshold=config.thresholds.latency,
    duration='5m',
    filters={ job: config.service_name }
  ),

  // Resource monitoring
  {
    alert: config.service_name + '_high_memory',
    expr: 'process_resident_memory_bytes{job="' + config.service_name + '"} / 1024 / 1024 > ' + config.thresholds.memory_mb,
    'for': '5m',
    labels: utils.labels.standard(config.service_name + '_memory') + {
      severity: 'warning',
      type: 'resource',
      service: config.service_name,
    },
    annotations: {
      summary: 'High memory usage for ' + config.service_name,
      description: 'Memory usage is {{ $value }}MB for {{ $labels.instance }}',
    },
  },

  {
    alert: config.service_name + '_high_cpu',
    expr: 'rate(process_cpu_seconds_total{job="' + config.service_name + '"}[5m]) * 100 > ' + config.thresholds.cpu_percent,
    'for': '5m',
    labels: utils.labels.standard(config.service_name + '_cpu') + {
      severity: 'warning', 
      type: 'resource',
      service: config.service_name,
    },
    annotations: {
      summary: 'High CPU usage for ' + config.service_name,
      description: 'CPU usage is {{ $value }}% for {{ $labels.instance }}',
    },
  },
];

// Recording rules for SLIs
local recordingRules = [
  prometheus.recordings.rule(
    config.service_name + ':request_rate',
    'sum(rate(http_requests_total{job="' + config.service_name + '"}[5m]))',
    utils.labels.standard(config.service_name + '_request_rate')
  ),

  prometheus.recordings.rule(
    config.service_name + ':error_rate',
    'sum(rate(http_requests_total{job="' + config.service_name + '",code=~"5.."}[5m])) / sum(rate(http_requests_total{job="' + config.service_name + '"}[5m]))',
    utils.labels.standard(config.service_name + '_error_rate')
  ),

  prometheus.recordings.sli.availability(
    config.service_name,
    'sum(rate(http_requests_total{job="' + config.service_name + '",code!~"5.."}[5m]))',
    'sum(rate(http_requests_total{job="' + config.service_name + '"}[5m]))',
    { service: config.service_name }
  ),
];

// Dashboard using Grafonnet templates with enhanced layout
local mainDashboard = grafonnet.dashboards.monitoring(
  config.service_name + ' Monitoring',
  config.service_name,
  config.environment,
  config.team
) + {
  dashboard+: {
    panels: grafonnet.layouts.monitoring(config.service_name) + [
      // Additional custom panels
      grafonnet.panelTemplates.requestRate('Request Rate Trends', config.service_name) + {
        targets: [
          {
            expr: 'sum(rate(http_requests_total{job=~"${service}"}[5m])) by (method)',
            legendFormat: '{{method}}',
            refId: 'A',
          },
          {
            expr: 'sum(rate(http_requests_total{job=~"${service}"}[1h])) by (method)',
            legendFormat: '{{method}} (1h avg)',
            refId: 'B',
          },
        ],
        gridPos: { h: 8, w: 24, x: 0, y: 16 },
      },
    ],
  },
};

// SLO dashboard
local sloDashboard = grafonnet.dashboards.slo(
  config.service_name + ' SLO',
  config.service_name,
  config.slos
);

// Generate complete monitoring configuration
{
  // Prometheus monitoring rules
  prometheusRule: prometheus.prometheusRule(
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
  ),

  // Main monitoring dashboard
  dashboard: mainDashboard,

  // SLO-focused dashboard
  sloDashboard: sloDashboard,

  // Configuration for reference
  config: config,

  // Usage instructions
  usage: {
    description: 'This template generates both Prometheus alerts and Grafana dashboards for comprehensive service monitoring',
    steps: [
      '1. Replace REPLACE_WITH_* placeholders in config section',
      '2. Adjust SLO targets and alert thresholds as needed',
      '3. Compile with: jsonnet this-file.jsonnet',
      '4. Apply PrometheusRule to your cluster',
      '5. Import dashboards to Grafana',
    ],
    requirements: [
      'Grafonnet library installed and available in import path',
      'Prometheus with service discovery configured',
      'Grafana with Prometheus datasource configured',
      'Service exposing standard HTTP metrics (http_requests_total, etc.)',
    ],
  },
}