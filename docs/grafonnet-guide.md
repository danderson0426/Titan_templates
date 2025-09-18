# Getting Started with Grafonnet Integration

This guide explains how to use Titan Templates with Grafonnet for programmatic dashboard generation.

## Prerequisites

1. **Install Jsonnet**
   ```bash
   # On macOS
   brew install jsonnet
   
   # On Ubuntu/Debian
   sudo apt-get install jsonnet
   
   # Or download from https://github.com/google/jsonnet/releases
   ```

2. **Install Grafonnet Library**
   
   **Option A: Using jsonnet-bundler (recommended)**
   ```bash
   # Install jsonnet-bundler
   go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
   
   # Initialize project and install Grafonnet
   jb init
   jb install github.com/grafana/grafonnet-lib/grafonnet
   ```
   
   **Option B: Manual installation**
   ```bash
   git clone https://github.com/grafana/grafonnet-lib.git
   export JSONNET_PATH="./grafonnet-lib:$JSONNET_PATH"
   ```

3. **Access to Prometheus and Grafana** in your environment

## Quick Start Examples

### 1. Basic Service Monitoring

Create `my-service-monitoring.jsonnet`:

```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

// Generate complete monitoring for a service
grafonnet.integration.monitoring(
  'user-service',        // service name
  'production',          // environment  
  'backend-team'         // team name
)
```

Compile and use:
```bash
# Generate the monitoring configuration
jsonnet my-service-monitoring.jsonnet > monitoring-output.json

# Extract Prometheus rules
jsonnet -e '(import "my-service-monitoring.jsonnet").prometheusRule' > prometheus-rules.yaml

# Extract dashboard  
jsonnet -e '(import "my-service-monitoring.jsonnet").dashboard' > dashboard.json
```

### 2. Custom Dashboard with Business Metrics

Create `custom-dashboard.jsonnet`:

```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

// Create base dashboard
local dashboard = grafonnet.dashboard.monitoring(
  'Payment Service Dashboard',
  'payment-service'
);

// Add custom business panels
local businessPanels = [
  grafonnet.panels.timeSeries.new(
    'Payment Success Rate',
    datasource='prometheus',
    unit='percent',
  ).addTarget(
    grafonnet.query.prometheus.new(
      'sum(rate(payment_success_total[5m])) / sum(rate(payment_total[5m])) * 100',
      legendFormat='Success Rate',
    )
  ),
];

// Combine standard and business panels
dashboard.addPanels(
  grafonnet.layout.monitoring('payment-service') + businessPanels
)
```

### 3. SLO Dashboard

Create `slo-dashboard.jsonnet`:

```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

// Define SLO targets
local slos = {
  availability: 99.95,  // 99.95%
  error_rate: 0.1,      // 0.1%  
  latency_p95: 200,     // 200ms
  latency_p99: 500,     // 500ms
};

// Generate SLO dashboard
grafonnet.dashboard.slo(
  'Payment Service SLO',
  'payment-service',
  slos
).addPanels(grafonnet.layout.slo('payment-service', slos))
```

## Integration with Existing Workflows

### GitOps Integration

```bash
# In your GitOps pipeline
jsonnet monitoring/*.jsonnet -o manifests/

# Apply to cluster
kubectl apply -f manifests/
```

### CI/CD Pipeline Example

```yaml
# .github/workflows/monitoring.yml
name: Generate Monitoring
on:
  push:
    paths: ['monitoring/**']

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt-get install jsonnet
          go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
          jb install
      
      - name: Generate monitoring config
        run: |
          mkdir -p output
          jsonnet monitoring/service-monitoring.jsonnet > output/monitoring.json
          
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: monitoring-config
          path: output/
```

## Best Practices

### 1. Configuration Management

Keep service configuration separate:

```jsonnet
// config.libsonnet
{
  services: {
    'payment-service': {
      environment: 'production',
      team: 'payments',
      slos: { availability: 99.95, error_rate: 0.1 },
    },
    'user-service': {
      environment: 'production', 
      team: 'identity',
      slos: { availability: 99.9, error_rate: 0.5 },
    },
  },
}
```

```jsonnet
// monitoring.jsonnet
local config = import 'config.libsonnet';
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

{
  [service]: grafonnet.integration.monitoring(
    service,
    config.services[service].environment,
    config.services[service].team,
    config.services[service].slos
  )
  for service in std.objectFields(config.services)
}
```

### 2. Custom Panel Library

Extend with your own panels:

```jsonnet
// custom-panels.libsonnet  
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

{
  businessMetrics: {
    paymentVolume(service)::
      grafonnet.panels.timeSeries.new(
        'Payment Volume',
        datasource='prometheus',
        unit='short',
      ).addTarget(
        grafonnet.query.prometheus.new(
          'sum(rate(payments_total{service="' + service + '"}[5m]))',
          legendFormat='Payments/sec',
        )
      ),
  },
}
```

### 3. Validation

Add validation to your templates:

```jsonnet
local utils = import 'jsonnet/lib/utils.libsonnet';

// Validate configuration
local config = { /* your config */ };
local validation = utils.validate.required(config, ['service', 'environment']);

// Your monitoring setup
{ /* ... */ }
```

## Troubleshooting

### Common Issues

1. **Grafonnet not found**
   ```
   RUNTIME ERROR: couldn't open import "grafonnet/grafana.libsonnet"
   ```
   **Solution:** Ensure Grafonnet is installed and in your import path.

2. **Panel positioning issues**
   ```jsonnet
   // Explicitly set grid positions
   panel + grafonnet.panel.gridPos.new(x, y, width, height)
   ```

3. **Query syntax errors**  
   Test queries in Grafana before adding to templates.

### Getting Help

- Check [Grafonnet documentation](https://github.com/grafana/grafonnet-lib)
- Review [Titan Templates examples](../jsonnet/examples/)
- Open issues in this repository for template-specific questions

## Next Steps

1. Try the examples in `jsonnet/examples/`
2. Adapt the templates in `jsonnet/templates/`
3. Build your own custom panels and layouts
4. Integrate with your CI/CD pipeline
5. Share your templates with the team