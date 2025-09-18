# Library Reference

This document provides detailed reference for all the functions and templates available in Titan Templates.

## Utils Library (`jsonnet/lib/utils.libsonnet`)

### Labels

#### `labels.standard(name, environment='production', team='platform')`
Creates standard labels for observability resources.

**Parameters:**
- `name` (string): Resource name
- `environment` (string): Environment name (default: 'production')
- `team` (string): Team name (default: 'platform')

**Returns:** Object with standard labels

**Example:**
```jsonnet
utils.labels.standard('my-service', 'staging', 'backend')
// Returns: { name: 'my-service', environment: 'staging', team: 'backend', managed_by: 'titan-templates' }
```

#### `labels.withCustom(standard_labels, custom_labels)`
Merges custom labels with standard ones.

### Time

#### `time.ranges`
Common time range constants:
- `last_5m`: '5m'
- `last_15m`: '15m'
- `last_30m`: '30m'
- `last_1h`: '1h'
- `last_6h`: '6h'
- `last_12h`: '12h'
- `last_24h`: '24h'
- `last_7d`: '7d'
- `last_30d`: '30d'

#### `time.toSeconds(timeStr)`
Converts time string to seconds.

**Parameters:**
- `timeStr` (string): Time string like '5m', '1h', '1d'

**Returns:** Number of seconds

### Format

#### `format.humanize(value, unit='')`
Formats numbers in human-readable format.

**Parameters:**
- `value` (number): Value to format
- `unit` (string): Unit suffix (optional)

**Returns:** Formatted string

**Example:**
```jsonnet
utils.format.humanize(1500000, 'bytes')  // '1.5Mbytes'
```

#### `format.colors`
Standard color palette:
- `green`: '#73BF69'
- `red`: '#F2495C'
- `yellow`: '#FF9830'
- `blue`: '#5794F2'
- `purple`: '#B877D9'
- `orange`: '#FF7043'
- `gray`: '#8E8E93'

### Validation

#### `validate.required(obj, fields)`
Validates that required fields are present in an object.

#### `validate.environment(env)`
Validates that environment is one of: 'development', 'staging', 'production'.

## Prometheus Library (`jsonnet/lib/prometheus.libsonnet`)

### Queries

#### `queries.rate(metric, range='5m', filters={})`
Creates a rate query for counters.

**Parameters:**
- `metric` (string): Metric name
- `range` (string): Time range (default: '5m')
- `filters` (object): Label filters

**Returns:** Prometheus query string

#### `queries.increase(metric, range='5m', filters={})`
Creates an increase query for counters.

#### `queries.quantile(metric, quantile=0.95, range='5m', filters={})`
Creates a histogram quantile query.

#### `queries.avgOverTime(metric, range='5m', filters={})`
Creates an average over time query.

### Alerts

#### `alerts.highErrorRate(name, metric, threshold=0.05, duration='5m', filters={})`
Creates a high error rate alert.

**Parameters:**
- `name` (string): Alert name
- `metric` (string): Metric name for error counting
- `threshold` (number): Error rate threshold (default: 0.05 = 5%)
- `duration` (string): Duration for alert condition
- `filters` (object): Label filters

**Returns:** Alert rule object

#### `alerts.highLatency(name, metric, threshold=1000, duration='5m', filters={})`
Creates a high latency alert (P95).

**Parameters:**
- `threshold` (number): Latency threshold in milliseconds

#### `alerts.serviceDown(name, metric='up', duration='1m', filters={})`
Creates a service availability alert.

### Recordings

#### `recordings.rule(name, query, labels={})`
Creates a recording rule.

#### `recordings.sli.availability(service, successMetric, totalMetric, filters={})`
Creates an availability SLI recording rule.

#### `recordings.sli.errorRate(service, errorMetric, totalMetric, filters={})`
Creates an error rate SLI recording rule.

### PrometheusRule

#### `prometheusRule(name, namespace='monitoring', groups=[])`
Creates a PrometheusRule CRD.

**Parameters:**
- `name` (string): Rule name
- `namespace` (string): Kubernetes namespace
- `groups` (array): Rule groups

## Grafana Libraries

### Custom Grafana Library (`jsonnet/lib/grafana.libsonnet`)

A lightweight custom library for basic Grafana dashboard generation.

#### Panels

##### `panels.timeSeries(title, targets=[], unit='short', min=null, max=null)`
Creates a time series panel for the new Grafana format.

##### `panels.stat(title, targets=[], unit='short', thresholds=[])`
Creates a stat panel.

##### `panels.table(title, targets=[], columns=[])`
Creates a table panel.

#### Targets

##### `targets.prometheus(expr, legendFormat='', interval='')`
Creates a Prometheus target.

##### `targets.prometheusMulti(queries)`
Creates multiple Prometheus targets with auto-assigned refIds.

#### Dashboard

##### `dashboard(title, description='', tags=[], panels=[], time_from='now-1h', time_to='now', refresh='30s')`
Creates a complete Grafana dashboard.

**Parameters:**
- `title` (string): Dashboard title
- `description` (string): Dashboard description
- `tags` (array): Dashboard tags
- `panels` (array): Dashboard panels
- `time_from` (string): Default time range start
- `time_to` (string): Default time range end
- `refresh` (string): Auto-refresh interval

### Grafonnet Integration Library (`jsonnet/lib/grafonnet.libsonnet`)

**Recommended approach** for production dashboards using the industry-standard Grafonnet library.

#### Prerequisites

Install Grafonnet library:
```bash
# Using jsonnet-bundler
jb install github.com/grafana/grafonnet-lib/grafonnet

# Or add to import path
git clone https://github.com/grafana/grafonnet-lib.git
```

#### Dashboard Creation

##### `dashboard.monitoring(title, service, environment='production', team='platform')`
Creates a standardized monitoring dashboard using Grafonnet.

**Example:**
```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

grafonnet.dashboard.monitoring(
  'My Service Dashboard',
  'my-service',
  'production',
  'backend-team'
)
```

##### `dashboard.slo(title, service, slos={})`
Creates an SLO-focused dashboard.

**Parameters:**
- `slos.availability` (number): Availability target (e.g., 99.9)
- `slos.error_rate` (number): Error rate threshold (e.g., 0.1)
- `slos.latency_p95` (number): P95 latency target in ms
- `slos.latency_p99` (number): P99 latency target in ms

#### Panels

##### `panels.serviceHealth(service)`
Service health indicator with up/down status.

##### `panels.requestRate(service, title='Request Rate')`
Request rate time series panel.

##### `panels.errorRate(service, title='Error Rate', warning=1, critical=5)`
Error rate panel with configurable thresholds.

##### `panels.latency(service, title='Response Time')`
Latency percentiles (P50, P95, P99) panel.

##### `panels.sloBurnRate(service, sloTarget=99.9, title='SLO Burn Rate')`
SLO error budget burn rate visualization.

##### `panels.resourceUsage(service, resource='memory', title=null)`
Resource usage panel for CPU or memory.

**Parameters:**
- `resource` (string): 'memory' or 'cpu'

#### Layout Helpers

##### `layout.monitoring(service)`
Standard monitoring layout with common panels.

##### `layout.slo(service, slos={})`
SLO-focused layout optimized for SLO monitoring.

#### Integration Functions

##### `integration.monitoring(service, environment='production', team='platform', slos={})`
Generates both PrometheusRule and Dashboard for complete monitoring setup.

**Returns:**
```jsonnet
{
  prometheusRule: { /* Prometheus alerts */ },
  dashboard: { /* Grafana dashboard */ }
}
```

**Example:**
```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

local monitoring = grafonnet.integration.monitoring(
  'payment-service',
  'production',
  'payments-team',
  { availability: 99.95, error_rate: 0.1 }
);

{
  prometheusRule: monitoring.prometheusRule,
  dashboard: monitoring.dashboard,
}
```

## Template Examples

### Basic Service Monitoring
File: `jsonnet/examples/basic-service-monitoring.jsonnet`

Simple monitoring setup with basic alerts for service availability, error rate, and latency.

### Web Service Monitoring
File: `jsonnet/templates/web-service-monitoring.jsonnet`

Comprehensive monitoring for HTTP services including:
- Request rate and error rate monitoring
- Latency tracking (P95)
- Resource usage alerts
- SLI recording rules

### Kubernetes Monitoring
File: `jsonnet/templates/kubernetes-monitoring.jsonnet`

Full Kubernetes cluster monitoring:
- Node health and resource alerts
- Pod lifecycle monitoring
- API server performance tracking

### SLO Monitoring Example
File: `jsonnet/examples/slo-monitoring-example.jsonnet`

Advanced SLO-based monitoring with:
- Automated SLI calculation
- SLO breach alerting
- Grafana dashboard generation

## Best Practices

### Alert Naming
- Use descriptive names: `service_condition_type`
- Include environment in labels
- Use consistent severity levels

### Threshold Setting
- Start conservative and adjust based on data
- Use percentage-based thresholds for error rates
- Consider business impact when setting SLO targets

### Dashboard Design
- Group related metrics
- Use template variables for filtering
- Include meaningful descriptions
- Maintain consistent time ranges

### Code Organization
- Keep configuration at the top of files
- Use local variables for reusable values
- Document complex expressions
- Follow consistent formatting