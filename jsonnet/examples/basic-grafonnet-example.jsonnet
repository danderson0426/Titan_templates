// Example: Basic dashboard generation with Grafonnet integration
// This shows how to use the Grafonnet integration library to generate dashboards
// alongside Prometheus alerts from Titan Templates

local prometheus = import '../lib/prometheus.libsonnet';
local grafonnet = import '../lib/grafonnet.libsonnet';

// Simple service configuration
local service = 'web-api';

// Generate basic alerts
local alerts = [
  prometheus.alerts.serviceDown(service + '_down', filters={ job: service }),
  prometheus.alerts.highErrorRate(service + '_errors', 'http_requests_total', 
    threshold=0.05, filters={ job: service, code: '~"5.."' }),
];

// Generate dashboard using Grafonnet integration  
local dashboard = grafonnet.dashboards.monitoring(
  service + ' Dashboard',
  service
);

// Output monitoring configuration
{
  // Prometheus monitoring rules
  prometheusRule: prometheus.prometheusRule(
    service + '-monitoring',
    'default',
    [{
      name: service + '-alerts', 
      rules: alerts,
    }]
  ),
  
  // Grafana dashboard (generated with Grafonnet templates)
  dashboard: dashboard,
  
  // Individual panels for reference
  panels: grafonnet.layouts.monitoring(service),
  
  // Queries for reference
  queries: {
    serviceHealth: grafonnet.queries.serviceHealth(service),
    requestRate: grafonnet.queries.requestRate(service),
    errorRate: grafonnet.queries.errorRate(service),
  },
}