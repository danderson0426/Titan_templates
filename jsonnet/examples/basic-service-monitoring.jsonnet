// Example: Simple usage of Titan Templates for basic service monitoring
local prometheus = import '../lib/prometheus.libsonnet';

// Basic service configuration
local config = {
  service: 'user-service',
  environment: 'staging',
  team: 'platform',
};

// Simple alert rules
local basicAlerts = [
  // Service is down
  prometheus.alerts.serviceDown(
    config.service + '_down',
    filters={ job: config.service }
  ),
  
  // High error rate (over 5%)
  prometheus.alerts.highErrorRate(
    config.service + '_errors',
    'http_requests_total',
    threshold=0.05,
    filters={ 
      job: config.service,
      code: '~"5.."' 
    }
  ),
  
  // High latency (over 1 second for P95)
  prometheus.alerts.highLatency(
    config.service + '_slow',
    'http_request_duration_seconds_bucket', 
    threshold=1.0,
    filters={ job: config.service }
  ),
];

// Generate PrometheusRule
prometheus.prometheusRule(
  config.service + '-basic-monitoring',
  'monitoring',
  [{
    name: config.service + '-alerts',
    rules: basicAlerts,
  }]
)