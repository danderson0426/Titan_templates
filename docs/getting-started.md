# Getting Started with Titan Templates

This guide will help you get started with using Titan Templates for your observability as code pipelines.

## Prerequisites

Before you begin, ensure you have:

1. **Jsonnet installed**: 
   ```bash
   # On macOS with Homebrew
   brew install jsonnet
   
   # On Ubuntu/Debian
   sudo apt-get install jsonnet
   
   # Or download from https://jsonnet.org/
   ```

2. **kubectl configured** (for Kubernetes deployments):
   ```bash
   kubectl version --client
   ```

3. **Access to Prometheus and Grafana** in your environment

## Your First Monitoring Setup

### Step 1: Clone and Explore

```bash
git clone https://github.com/danderson0426/Titan_templates.git
cd Titan_templates

# Explore the structure
tree jsonnet/
```

### Step 2: Create Basic Service Monitoring

Create a new file `my-service-monitoring.jsonnet`:

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';
local utils = import 'jsonnet/lib/utils.libsonnet';

// Configure your service
local config = {
  service: 'my-web-service',
  environment: 'production',
  team: 'my-team',
  namespace: 'default',
};

// Create basic alerts
local alerts = [
  prometheus.alerts.serviceDown(
    config.service + '_down',
    filters={ job: config.service }
  ),
  prometheus.alerts.highErrorRate(
    config.service + '_high_errors',
    'http_requests_total',
    threshold=0.05,  // 5% error rate
    filters={ job: config.service, code: '~"5.."' }
  ),
];

// Generate PrometheusRule
prometheus.prometheusRule(
  config.service + '-monitoring',
  config.namespace,
  [{
    name: config.service + '-alerts',
    rules: alerts,
  }]
)
```

### Step 3: Compile and Deploy

```bash
# Compile to YAML
jsonnet my-service-monitoring.jsonnet > my-service-rules.yaml

# Review the output
cat my-service-rules.yaml

# Apply to Kubernetes
kubectl apply -f my-service-rules.yaml
```

### Step 4: Import Grafana Dashboard

1. Open Grafana
2. Go to **Dashboards** → **Import**
3. Upload `grafana/templates/web-service-dashboard.json`
4. Configure your data source and variables

## Common Patterns

### Pattern 1: Service-Level Objectives (SLOs)

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

local slos = {
  availability: 99.9,   // 99.9% uptime
  error_rate: 0.1,      // < 0.1% errors
  latency_p95: 500,     // < 500ms P95
};

// Create SLO-based alerts
local sloAlerts = [
  // Availability SLO breach
  prometheus.alerts.serviceDown(
    'api_availability_slo_breach',
    duration='2m',  // Tight SLO monitoring
    filters={ job: 'api' }
  ),
  
  // Error budget burn rate
  {
    alert: 'HighErrorBudgetBurnRate',
    expr: 'api:error_rate_sli > ' + (slos.error_rate * 10),  // 10x normal rate
    'for': '5m',
    labels: { severity: 'critical' },
    annotations: {
      summary: 'High error budget burn rate',
    },
  },
];
```

### Pattern 2: Multi-Environment Monitoring

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

local environments = ['staging', 'production'];
local services = ['api', 'worker', 'frontend'];

// Generate alerts for all environment/service combinations
local allAlerts = std.flattenArrays([
  [
    prometheus.alerts.serviceDown(
      service + '_' + env + '_down',
      filters={ 
        job: service,
        environment: env 
      }
    )
    for service in services
  ]
  for env in environments
]);
```

### Pattern 3: Infrastructure Monitoring

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

// Node-level alerts
local nodeAlerts = [
  {
    alert: 'NodeDiskSpaceRunningOut',
    expr: 'node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"} * 100 < 10',
    'for': '10m',
    labels: { severity: 'warning' },
    annotations: {
      summary: 'Node disk space running out',
      description: 'Disk space is below 10% on {{ $labels.instance }}',
    },
  },
];
```

## Troubleshooting

### Common Issues

1. **Jsonnet compilation errors**:
   ```bash
   # Check syntax
   jsonnet --lint my-file.jsonnet
   ```

2. **Import path issues**:
   ```bash
   # Ensure you're running from the repository root
   # Use relative paths from the file's location
   ```

3. **Kubernetes apply failures**:
   ```bash
   # Validate YAML before applying
   kubectl apply --dry-run=client -f my-rules.yaml
   ```

### Debugging Tips

1. **Use `std.trace()` for debugging**:
   ```jsonnet
   local debug = std.trace('Config: ' + std.toString(config), config);
   ```

2. **Test queries in Prometheus UI** before putting them in alerts

3. **Start simple and iterate** - begin with basic alerts and add complexity

## Next Steps

1. **Explore Examples**: Check out `jsonnet/examples/` for more patterns
2. **Customize Templates**: Modify existing templates for your needs
3. **Create Custom Libraries**: Extend the base libraries with your patterns
4. **Set up CI/CD**: Automate compilation and deployment of your monitoring

## Additional Resources

- [Jsonnet Tutorial](https://jsonnet.org/learning/tutorial.html)
- [Prometheus Alerting Best Practices](https://prometheus.io/docs/practices/alerting/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [SRE Workbook](https://sre.google/workbook/table-of-contents/)