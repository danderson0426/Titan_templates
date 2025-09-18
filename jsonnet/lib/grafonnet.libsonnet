// Grafonnet library integration for Titan Templates
// Provides high-level functions that integrate with Grafonnet for dashboard generation
// This complements the custom grafana.libsonnet functions with industry-standard Grafonnet

// This library provides templates that can be used with Grafonnet
// Users need to install Grafonnet separately: https://github.com/grafana/grafonnet-lib
// When Grafonnet is available, these functions provide high-level abstractions

local utils = import 'utils.libsonnet';

{
  // Configuration for Grafonnet integration
  config: {
    // Default datasource configuration
    datasource: {
      prometheus: 'prometheus',
    },
    
    // Standard time ranges
    timeRanges: {
      default_from: 'now-1h',
      default_to: 'now',
      refresh: '30s',
    },

    // Panel dimensions
    panelDefaults: {
      height: 8,
      width: 12,
    },
  },

  // Template variables for dashboards
  variables: {
    // Service selection variable
    service(serviceName=null):: {
      name: 'service',
      type: 'query',
      query: if serviceName != null then 
        'label_values(up{job=~".*' + serviceName + '.*"}, job)'
      else
        'label_values(up, job)',
      datasource: '${datasource}',
      refresh: 1,
      includeAll: true,
      multi: true,
      current: { text: 'All', value: '$__all' },
    },

    // Instance selection variable  
    instance():: {
      name: 'instance',
      type: 'query',
      query: 'label_values(up{job=~"${service}"}, instance)',
      datasource: '${datasource}',
      refresh: 1,
      includeAll: true,
      multi: true,
      current: { text: 'All', value: '$__all' },
    },

    // Datasource variable
    datasource():: {
      name: 'datasource',
      type: 'datasource',
      query: 'prometheus',
      current: { text: 'Prometheus', value: 'prometheus' },
    },
  },

  // Prometheus query templates optimized for Grafonnet usage
  queries: {
    // Service health query
    serviceHealth(service='${service}'):: 
      'up{job=~"' + service + '"}',

    // Request rate query
    requestRate(service='${service}', interval='5m')::
      'sum(rate(http_requests_total{job=~"' + service + '"}[' + interval + '])) by (job)',

    // Error rate query  
    errorRate(service='${service}', interval='5m')::
      'sum(rate(http_requests_total{job=~"' + service + '",code=~"5.."}[' + interval + '])) by (job) / sum(rate(http_requests_total{job=~"' + service + '"}[' + interval + '])) by (job) * 100',

    // Latency percentile queries
    latency: {
      p50(service='${service}', interval='5m')::
        'histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{job=~"' + service + '"}[' + interval + '])) by (le, job)) * 1000',
      
      p95(service='${service}', interval='5m')::
        'histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job=~"' + service + '"}[' + interval + '])) by (le, job)) * 1000',
      
      p99(service='${service}', interval='5m')::
        'histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job=~"' + service + '"}[' + interval + '])) by (le, job)) * 1000',
    },

    // Resource usage queries
    resources: {
      memory(service='${service}')::
        'process_resident_memory_bytes{job=~"' + service + '"} / 1024 / 1024',
      
      cpu(service='${service}', interval='5m')::
        'rate(process_cpu_seconds_total{job=~"' + service + '"}[' + interval + ']) * 100',
    },

    // SLO-related queries
    slo: {
      availability(service='${service}', interval='5m')::
        'sum(rate(http_requests_total{job=~"' + service + '",code!~"5.."}[' + interval + '])) by (job) / sum(rate(http_requests_total{job=~"' + service + '"}[' + interval + '])) by (job) * 100',
      
      errorBudgetBurn(service='${service}', interval='5m')::
        '(1 - (sum(rate(http_requests_total{job=~"' + service + '",code!~"5.."}[' + interval + '])) by (job) / sum(rate(http_requests_total{job=~"' + service + '"}[' + interval + '])) by (job))) * 100',
    },
  },

  // Panel templates using standard Grafana panel format
  // These can be used directly or as templates for Grafonnet panels
  panelTemplates: {
    // Service health stat panel
    serviceHealth(title='Service Health', service='${service}'):: {
      title: title,
      type: 'stat',
      targets: [{
        expr: $.queries.serviceHealth(service),
        legendFormat: '{{instance}}',
        refId: 'A',
      }],
      fieldConfig: {
        defaults: {
          color: { mode: 'thresholds' },
          mappings: [
            { options: { '0': { text: 'Down', color: utils.format.colors.red } } },
            { options: { '1': { text: 'Up', color: utils.format.colors.green } } },
          ],
          thresholds: {
            mode: 'absolute',
            steps: [
              { color: utils.format.colors.red, value: 0 },
              { color: utils.format.colors.green, value: 1 },
            ],
          },
          unit: 'short',
        },
      },
      options: {
        colorMode: 'background',
        graphMode: 'area',
        justifyMode: 'auto',
        orientation: 'auto',
        reduceOptions: {
          calcs: ['lastNotNull'],
          fields: '',
          values: false,
        },
        textMode: 'auto',
      },
    },

    // Request rate time series panel
    requestRate(title='Request Rate', service='${service}'):: {
      title: title,
      type: 'timeseries',
      targets: [{
        expr: $.queries.requestRate(service),
        legendFormat: '{{job}}',
        refId: 'A',
      }],
      fieldConfig: {
        defaults: {
          color: { mode: 'palette-classic' },
          unit: 'reqps',
        },
      },
      options: {
        legend: {
          calcs: [],
          displayMode: 'list',
          placement: 'bottom',
        },
        tooltip: {
          mode: 'single',
          sort: 'none',
        },
      },
    },

    // Error rate with thresholds
    errorRate(title='Error Rate', service='${service}', warning=1, critical=5):: {
      title: title,
      type: 'timeseries',
      targets: [{
        expr: $.queries.errorRate(service),
        legendFormat: '{{job}} error rate',
        refId: 'A',
      }],
      fieldConfig: {
        defaults: {
          color: { mode: 'thresholds' },
          unit: 'percent',
          thresholds: {
            mode: 'absolute',
            steps: [
              { color: utils.format.colors.green, value: 0 },
              { color: utils.format.colors.yellow, value: warning },
              { color: utils.format.colors.red, value: critical },
            ],
          },
        },
        overrides: [{
          matcher: { id: 'byName', options: 'Error Rate' },
          properties: [{
            id: 'custom.fillOpacity',
            value: 10,
          }],
        }],
      },
    },

    // Latency percentiles panel
    latency(title='Response Time', service='${service}'):: {
      title: title,
      type: 'timeseries',
      targets: [
        {
          expr: $.queries.latency.p50(service),
          legendFormat: '{{job}} p50',
          refId: 'A',
        },
        {
          expr: $.queries.latency.p95(service),
          legendFormat: '{{job}} p95',
          refId: 'B',
        },
        {
          expr: $.queries.latency.p99(service),
          legendFormat: '{{job}} p99',
          refId: 'C',
        },
      ],
      fieldConfig: {
        defaults: {
          color: { mode: 'palette-classic' },
          unit: 'ms',
        },
      },
    },

    // Resource usage panel
    resourceUsage(resource='memory', title=null, service='${service}')::
      local panelTitle = if title != null then title 
        else std.asciiUpper(std.substr(resource, 0, 1)) + std.substr(resource, 1, std.length(resource)) + ' Usage';
      local query = if resource == 'memory' then $.queries.resources.memory(service)
        else if resource == 'cpu' then $.queries.resources.cpu(service)
        else error 'Unsupported resource type: ' + resource;
      local unit = if resource == 'memory' then 'MB' else if resource == 'cpu' then 'percent' else 'short';
      
      {
        title: panelTitle,
        type: 'timeseries',
        targets: [{
          expr: query,
          legendFormat: '{{instance}}',
          refId: 'A',
        }],
        fieldConfig: {
          defaults: {
            color: { mode: 'palette-classic' },
            unit: unit,
          },
        },
      },

    // SLO burn rate panel
    sloBurnRate(title='SLO Burn Rate', service='${service}', sloTarget=99.9):: {
      title: title,
      type: 'timeseries',
      targets: [{
        expr: $.queries.slo.errorBudgetBurn(service),
        legendFormat: '{{job}} error budget burn',
        refId: 'A',
      }],
      fieldConfig: {
        defaults: {
          color: { mode: 'thresholds' },
          unit: 'percent',
          thresholds: {
            mode: 'absolute',
            steps: [
              { color: utils.format.colors.green, value: 0 },
              { color: utils.format.colors.yellow, value: (100 - sloTarget) * 2 },
              { color: utils.format.colors.red, value: (100 - sloTarget) * 10 },
            ],
          },
        },
      },
    },
  },

  // Dashboard layouts
  layouts: {
    // Standard monitoring layout with grid positions
    monitoring(service='${service}'):: [
      $.panelTemplates.serviceHealth('Service Health', service) + { gridPos: { h: 8, w: 6, x: 0, y: 0 } },
      $.panelTemplates.requestRate('Request Rate', service) + { gridPos: { h: 8, w: 6, x: 6, y: 0 } },
      $.panelTemplates.errorRate('Error Rate', service) + { gridPos: { h: 8, w: 6, x: 12, y: 0 } },
      $.panelTemplates.latency('Response Time', service) + { gridPos: { h: 8, w: 6, x: 18, y: 0 } },
      $.panelTemplates.resourceUsage('cpu', 'CPU Usage', service) + { gridPos: { h: 8, w: 12, x: 0, y: 8 } },
      $.panelTemplates.resourceUsage('memory', 'Memory Usage', service) + { gridPos: { h: 8, w: 12, x: 12, y: 8 } },
    ],

    // SLO-focused layout
    slo(service='${service}', slos={}):: [
      $.panelTemplates.serviceHealth('Service Health', service) + { gridPos: { h: 8, w: 8, x: 0, y: 0 } },
      $.panelTemplates.sloBurnRate('SLO Burn Rate', service, slos.availability) + { gridPos: { h: 8, w: 8, x: 8, y: 0 } },
      $.panelTemplates.errorRate('Error Rate', service) + { gridPos: { h: 8, w: 8, x: 16, y: 0 } },
      $.panelTemplates.latency('Response Time', service) + { gridPos: { h: 8, w: 24, x: 0, y: 8 } },
    ],
  },

  // Dashboard templates
  dashboards: {
    // Standard monitoring dashboard
    monitoring(title, service, environment='production', team='platform'):: {
      dashboard: {
        id: null,
        title: title,
        description: 'Generated monitoring dashboard for ' + service,
        tags: ['monitoring', service, environment, team],
        timezone: 'browser',
        refresh: $.config.timeRanges.refresh,
        time: {
          from: $.config.timeRanges.default_from,
          to: $.config.timeRanges.default_to,
        },
        templating: {
          list: [
            $.variables.datasource(),
            $.variables.service(service),
            $.variables.instance(),
          ],
        },
        panels: [
          $.layouts.monitoring(service)[i] + { id: i + 1 }
          for i in std.range(0, std.length($.layouts.monitoring(service)) - 1)
        ],
        schemaVersion: 16,
        version: 1,
      },
    },

    // SLO dashboard
    slo(title, service, slos={}):: {
      dashboard: {
        id: null,
        title: title,
        description: 'SLO monitoring for ' + service,
        tags: ['slo', 'monitoring', service],
        timezone: 'browser',
        refresh: '1m',
        time: {
          from: 'now-24h',
          to: 'now',
        },
        templating: {
          list: [
            $.variables.datasource(),
            $.variables.service(service),
            $.variables.instance(),
          ],
        },
        panels: [
          $.layouts.slo(service, slos)[i] + { id: i + 1 }
          for i in std.range(0, std.length($.layouts.slo(service, slos)) - 1)
        ],
        schemaVersion: 16,
        version: 1,
      },
    },
  },

  // Integration helpers
  integration: {
    // Generate both PrometheusRule and Dashboard for a service  
    monitoring(service, environment='production', team='platform', slos={})::
      local prometheus = import 'prometheus.libsonnet';
      
      // Alert rules
      local alerts = [
        prometheus.alerts.serviceDown(
          service + '_down',
          filters={ job: service }
        ),
        prometheus.alerts.highErrorRate(
          service + '_high_error_rate',
          'http_requests_total',
          threshold=0.05,
          filters={ job: service, code: '~"5.."' }
        ),
        prometheus.alerts.highLatency(
          service + '_high_latency',
          'http_request_duration_seconds_bucket',
          threshold=1.0,
          filters={ job: service }
        ),
      ];

      // Dashboard
      local dashboard = $.dashboards.monitoring(
        service + ' Monitoring',
        service,
        environment,
        team
      );

      {
        prometheusRule: prometheus.prometheusRule(
          service + '-monitoring',
          'monitoring',
          [{
            name: service + '-alerts',
            rules: alerts,
          }]
        ),
        dashboard: dashboard,
      },
  },

  // Usage instructions and documentation
  docs: {
    description: 'Grafonnet integration library for Titan Templates',
    usage: {
      installation: [
        'Install Grafonnet: jb install github.com/grafana/grafonnet-lib/grafonnet',
        'Or: git clone https://github.com/grafana/grafonnet-lib.git',
        'Set JSONNET_PATH to include Grafonnet location',
      ],
      examples: [
        'Basic monitoring: grafonnet.integration.monitoring("my-service")',
        'SLO dashboard: grafonnet.dashboards.slo("My Service SLO", "my-service", slos)',
        'Custom layout: grafonnet.layouts.monitoring("my-service")',
      ],
    },
    compatibility: {
      grafonnet_version: 'Compatible with Grafonnet v7.0+',
      grafana_version: 'Supports Grafana 8.0+',
      features: [
        'Template variables for service and instance filtering',
        'Standard panel types: timeseries, stat, table',
        'SLO-focused dashboard layouts',
        'Integration with Prometheus alerts',
        'Configurable thresholds and colors',
      ],
    },
  },
}