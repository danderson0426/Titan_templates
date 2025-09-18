// Example: Complete monitoring setup using Grafonnet templates
// This example shows how to create both Prometheus alerts and Grafana dashboards
// using Grafonnet integration alongside the existing Titan Templates libraries

local prometheus = import '../lib/prometheus.libsonnet';
local grafonnet = import '../lib/grafonnet.libsonnet';
local utils = import '../lib/utils.libsonnet';

// Service configuration
local config = {
  service: 'payment-service',
  environment: 'production',
  team: 'payments',
  namespace: 'default',
  
  // SLO targets
  slos: {
    availability: 99.95,  // 99.95% availability
    error_rate: 0.1,      // 0.1% error rate
    latency_p95: 200,     // 200ms P95 latency
    latency_p99: 500,     // 500ms P99 latency
  },
};

// Generate complete monitoring setup using Grafonnet integration
local monitoring = grafonnet.integration.monitoring(
  config.service,
  config.environment, 
  config.team,
  config.slos
);

// Additional custom alert for business-specific metrics
local businessAlerts = [
  {
    alert: config.service + '_failed_payments_high',
    expr: 'sum(rate(payment_transactions_total{job="' + config.service + '",status="failed"}[5m])) / sum(rate(payment_transactions_total{job="' + config.service + '"}[5m])) * 100 > 1.0',
    'for': '2m',
    labels: utils.labels.standard(config.service + '_business') + {
      severity: 'critical',
      type: 'business',
      service: config.service,
    },
    annotations: {
      summary: 'High payment failure rate',
      description: 'Payment failure rate is {{ $value }}% for {{ $labels.job }}',
      runbook_url: 'https://wiki.company.com/runbooks/payment-failures',
    },
  },
  
  {
    alert: config.service + '_transaction_volume_low',
    expr: 'sum(rate(payment_transactions_total{job="' + config.service + '"}[5m])) < 10',
    'for': '5m',
    labels: utils.labels.standard(config.service + '_business') + {
      severity: 'warning',
      type: 'business',
      service: config.service,
    },
    annotations: {
      summary: 'Low payment transaction volume',
      description: 'Payment transaction rate is only {{ $value }} transactions/sec',
    },
  },
];

// Enhanced dashboard with business metrics using panel templates
local businessPanels = [
  grafonnet.panelTemplates.requestRate('Payment Success Rate', config.service) + {
    targets: [{
      expr: 'sum(rate(payment_transactions_total{job=~"${service}",status="success"}[5m])) by (job) / sum(rate(payment_transactions_total{job=~"${service}"}[5m])) by (job) * 100',
      legendFormat: '{{job}} success rate',
      refId: 'A',
    }],
    fieldConfig+: { defaults+: { unit: 'percent' } },
    gridPos: { h: 8, w: 12, x: 0, y: 16 },
  },
  
  grafonnet.panelTemplates.requestRate('Payment Volume by Type', config.service) + {
    targets: [{
      expr: 'sum(rate(payment_transactions_total{job=~"${service}"}[5m])) by (payment_type)',
      legendFormat: '{{payment_type}}',
      refId: 'A',
    }],
    gridPos: { h: 8, w: 12, x: 12, y: 16 },
  },
];

// Create enhanced dashboard
local enhancedDashboard = grafonnet.dashboards.monitoring(
  config.service + ' Complete Monitoring',
  config.service,
  config.environment,
  config.team
) + {
  dashboard+: {
    panels: monitoring.dashboard.dashboard.panels + [
      businessPanels[i] + { id: std.length(monitoring.dashboard.dashboard.panels) + i + 1 }
      for i in std.range(0, std.length(businessPanels) - 1)
    ],
  },
};

// Enhanced PrometheusRule with business alerts
local enhancedPrometheusRule = prometheus.prometheusRule(
  config.service + '-complete-monitoring',
  config.namespace,
  [
    // Include standard monitoring alerts
    monitoring.prometheusRule.spec.groups[0],
    // Add business-specific alerts
    {
      name: config.service + '-business-alerts',
      interval: '30s',
      rules: businessAlerts,
    },
  ]
);

// Output both monitoring resources
{
  // Prometheus alerts (both standard and business)
  prometheusRule: enhancedPrometheusRule,
  
  // Grafana dashboard with both technical and business metrics
  dashboard: enhancedDashboard,
  
  // Optional: SLO-specific dashboard
  sloDashboard: grafonnet.dashboards.slo(
    config.service + ' SLO',
    config.service,
    config.slos
  ),
  
  // Configuration summary for documentation
  config: config,
  
  // Available queries and panels for reference
  reference: {
    queries: grafonnet.queries,
    panelTemplates: std.objectFields(grafonnet.panelTemplates),
    layouts: std.objectFields(grafonnet.layouts),
  },
}