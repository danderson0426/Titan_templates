// Prometheus-specific functions and templates
local utils = import 'utils.libsonnet';

{
  // Common Prometheus query patterns
  queries: {
    // Rate calculation for counters
    rate(metric, range='5m', filters={})::
      local filterStr = std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]);
      local filterPart = if std.length(filterStr) > 0 then '{' + filterStr + '}' else '';
      'rate(' + metric + filterPart + '[' + range + '])',
    
    // Increase calculation for counters
    increase(metric, range='5m', filters={})::
      local filterStr = std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]);
      local filterPart = if std.length(filterStr) > 0 then '{' + filterStr + '}' else '';
      'increase(' + metric + filterPart + '[' + range + '])',
    
    // Histogram quantile
    quantile(metric, quantile=0.95, range='5m', filters={})::
      local filterStr = std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]);
      local filterPart = if std.length(filterStr) > 0 then '{' + filterStr + '}' else '';
      'histogram_quantile(' + quantile + ', rate(' + metric + filterPart + '[' + range + ']))',
    
    // Average over time
    avgOverTime(metric, range='5m', filters={})::
      local filterStr = std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]);
      local filterPart = if std.length(filterStr) > 0 then '{' + filterStr + '}' else '';
      'avg_over_time(' + metric + filterPart + '[' + range + '])',
  },

  // Alert rule templates
  alerts: {
    // High error rate alert
    highErrorRate(name, metric, threshold=0.05, duration='5m', filters={}):: 
      local filterStr = std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]);
      local filterPart = if std.length(filterStr) > 0 then '{' + filterStr + '}' else '';
      {
        alert: name,
        expr: 'rate(' + metric + filterPart + '[' + duration + ']) > ' + threshold,
        'for': duration,
        labels: utils.labels.standard(name) + {
          severity: 'warning',
          type: 'error_rate',
        },
        annotations: {
          summary: 'High error rate detected',
          description: 'Error rate is {{ $value | humanizePercentage }} for {{ $labels.instance }}',
        },
      },
    
    // High latency alert
    highLatency(name, metric, threshold=1000, duration='5m', filters={}):: 
      local filterStr = std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]);
      local filterPart = if std.length(filterStr) > 0 then '{' + filterStr + '}' else '';
      {
        alert: name,
        expr: 'histogram_quantile(0.95, rate(' + metric + filterPart + '[' + duration + '])) > ' + threshold,
        'for': duration,
        labels: utils.labels.standard(name) + {
          severity: 'warning',
          type: 'latency',
        },
        annotations: {
          summary: 'High latency detected',
          description: '95th percentile latency is {{ $value }}ms for {{ $labels.instance }}',
        },
      },
    
    // Service down alert
    serviceDown(name, metric='up', duration='1m', filters={}):: {
      alert: name,
      expr: metric + '{' + std.join(',', [k + '="' + filters[k] + '"' for k in std.objectFields(filters)]) + '} == 0',
      'for': duration,
      labels: utils.labels.standard(name) + {
        severity: 'critical',
        type: 'availability',
      },
      annotations: {
        summary: 'Service is down',
        description: 'Service {{ $labels.instance }} has been down for more than ' + duration,
      },
    },
  },

  // Recording rule templates
  recordings: {
    // Create a recording rule
    rule(name, query, labels={}):: {
      record: name,
      expr: query,
      labels: labels,
    },
    
    // Common SLI recording rules
    sli: {
      // Availability SLI
      availability(service, successMetric, totalMetric, filters={}):: {
        record: service + ':availability',
        expr: '(' + successMetric + ' / ' + totalMetric + ') * 100',
        labels: utils.labels.standard(service + '_availability') + filters,
      },
      
      // Error rate SLI
      errorRate(service, errorMetric, totalMetric, filters={}):: {
        record: service + ':error_rate',
        expr: '(' + errorMetric + ' / ' + totalMetric + ') * 100',
        labels: utils.labels.standard(service + '_error_rate') + filters,
      },
    },
  },

  // PrometheusRule CRD template
  prometheusRule(name, namespace='monitoring', groups=[]):: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: {
      name: name,
      namespace: namespace,
      labels: utils.labels.standard(name),
    },
    spec: {
      groups: groups,
    },
  },
}