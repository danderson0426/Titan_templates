# Titan Templates - Observability as Code Library

A comprehensive library of Jsonnet and Grafana-compatible templates for building robust observability pipelines. This repository provides reusable components, best practices, and ready-to-use templates for monitoring, alerting, and dashboards.

## 🎯 Purpose

Titan Templates enables teams to implement observability as code by providing:
- **Reusable Jsonnet libraries** for common monitoring patterns
- **Pre-built Grafana dashboards** for various use cases
- **Standardized alert rules** following SRE best practices
- **Template examples** for quick starts and learning

## 📁 Repository Structure

```
titan_templates/
├── jsonnet/                    # Jsonnet libraries and templates
│   ├── lib/                   # Core library functions
│   │   ├── utils.libsonnet    # Common utilities and helpers
│   │   ├── prometheus.libsonnet # Prometheus-specific functions
│   │   └── grafana.libsonnet  # Grafana dashboard utilities
│   ├── templates/             # Ready-to-use templates
│   │   ├── web-service-monitoring.jsonnet
│   │   └── kubernetes-monitoring.jsonnet
│   └── examples/              # Usage examples
│       ├── basic-service-monitoring.jsonnet
│       └── slo-monitoring-example.jsonnet
├── grafana/                   # Grafana dashboard templates
│   ├── templates/             # Dashboard JSON files
│   │   ├── web-service-dashboard.json
│   │   └── kubernetes-cluster-dashboard.json
│   └── examples/              # Example configurations
└── docs/                      # Additional documentation
```

## 🚀 Quick Start

### Basic Service Monitoring

Create a simple monitoring setup for your web service:

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

local config = {
  service: 'my-api',
  environment: 'production',
};

// Basic alerts
local alerts = [
  prometheus.alerts.serviceDown(config.service + '_down', 
    filters={ job: config.service }
  ),
  prometheus.alerts.highErrorRate(config.service + '_errors',
    'http_requests_total', threshold=0.05,
    filters={ job: config.service, code: '~"5.."' }
  ),
];

// Generate PrometheusRule
prometheus.prometheusRule(config.service + '-monitoring', 'monitoring', [{
  name: config.service + '-alerts',
  rules: alerts,
}])
```

### Compile and Apply

```bash
# Compile Jsonnet to YAML
jsonnet jsonnet/examples/basic-service-monitoring.jsonnet | kubectl apply -f -

# Or save to file first
jsonnet jsonnet/examples/basic-service-monitoring.jsonnet > monitoring-rules.yaml
kubectl apply -f monitoring-rules.yaml
```

## 📚 Library Components

### Core Utilities (`utils.libsonnet`)

- **Labels**: Standardized labeling functions
- **Time**: Time range utilities and conversions
- **Format**: Number formatting and color palettes
- **Validation**: Input validation helpers

```jsonnet
local utils = import 'jsonnet/lib/utils.libsonnet';

// Standard labels
utils.labels.standard('my-service', 'production', 'backend-team')

// Time utilities
utils.time.ranges.last_24h  // '24h'
utils.time.toSeconds('5m')  // 300

// Formatting
utils.format.humanize(1500000, 'bytes')  // '1.5MB'
```

### Prometheus Library (`prometheus.libsonnet`)

Pre-built functions for common Prometheus patterns:

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

// Query patterns
prometheus.queries.rate('http_requests_total', '5m', {job: 'api'})
prometheus.queries.quantile('http_request_duration_seconds_bucket', 0.95)

// Alert templates
prometheus.alerts.highErrorRate('api_errors', 'http_requests_total', threshold=0.05)
prometheus.alerts.serviceDown('api_down', filters={job: 'api'})

// Recording rules
prometheus.recordings.sli.availability('api', successMetric, totalMetric)
```

### Grafana Library (`grafana.libsonnet`)

Dashboard and panel utilities:

```jsonnet
local grafana = import 'jsonnet/lib/grafana.libsonnet';

// Create panels
grafana.panels.timeSeries('Request Rate', targets, 'reqps')
grafana.panels.stat('Error Rate', targets, 'percent', [1, 5])

// Create complete dashboard
grafana.dashboard('Service Overview', 'My service dashboard', 
  tags=['monitoring'], panels=myPanels)
```

## 🎯 Templates

### Web Service Monitoring

Comprehensive monitoring for HTTP services including:
- Request rate, error rate, and latency alerts
- Resource usage monitoring (CPU, memory)
- SLI/SLO tracking
- Custom recording rules

**Usage:**
```bash
jsonnet jsonnet/templates/web-service-monitoring.jsonnet
```

### Kubernetes Cluster Monitoring

Full cluster monitoring covering:
- Node health and resource usage
- Pod lifecycle and restart alerts
- API server performance
- Control plane monitoring

**Usage:**
```bash
jsonnet jsonnet/templates/kubernetes-monitoring.jsonnet
```

## 📊 Grafana Dashboards

### Web Service Dashboard

A complete dashboard for web service monitoring featuring:
- Service status and health indicators
- Request rate and error rate trends
- Response time distributions
- Resource usage charts

**Import:** Use the JSON file in `grafana/templates/web-service-dashboard.json`

### Kubernetes Cluster Dashboard

Comprehensive cluster overview including:
- Cluster health and node status
- Pod distribution and status
- Resource usage trends
- Top consumers by CPU/memory

**Import:** Use the JSON file in `grafana/templates/kubernetes-cluster-dashboard.json`

## 🔧 Advanced Usage

### SLO Monitoring Example

Create Service Level Objective monitoring with automatic SLI calculation and alerting:

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';
local grafana = import 'jsonnet/lib/grafana.libsonnet';

local slos = {
  availability: 99.9,  // 99.9%
  error_rate: 0.1,     // 0.1%
  latency_p95: 500,    // 500ms
};

// See jsonnet/examples/slo-monitoring-example.jsonnet for complete implementation
```

### Custom Extensions

Extend the library for your specific needs:

```jsonnet
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

// Custom alert for your specific metric
local myCustomAlert = prometheus.alerts.highErrorRate(
  'custom_business_metric_alert',
  'business_transactions_total',
  threshold=0.02,
  filters={ type: 'payment', status: 'failed' }
);
```

## 🛠️ Development

### Prerequisites

- [Jsonnet](https://jsonnet.org/) for compiling templates
- [jb (Jsonnet Bundler)](https://github.com/jsonnet-bundler/jsonnet-bundler) for dependency management (optional)
- kubectl for applying Kubernetes resources
- Grafana for importing dashboards

### Local Development

```bash
# Clone the repository
git clone https://github.com/danderson0426/Titan_templates.git
cd Titan_templates

# Test compilation
jsonnet jsonnet/examples/basic-service-monitoring.jsonnet

# Validate output
jsonnet jsonnet/examples/basic-service-monitoring.jsonnet | kubectl apply --dry-run=client -f -
```

### Testing Templates

```bash
# Test all templates compile successfully
for file in jsonnet/templates/*.jsonnet; do
  echo "Testing $file..."
  jsonnet "$file" > /dev/null && echo "✓ OK" || echo "✗ FAILED"
done

# Test examples
for file in jsonnet/examples/*.jsonnet; do
  echo "Testing $file..."
  jsonnet "$file" > /dev/null && echo "✓ OK" || echo "✗ FAILED"
done
```

## 📖 Best Practices

### Naming Conventions

- Use descriptive alert names: `service_name_condition_type`
- Include environment in labels: `{environment: "production"}`
- Use consistent metric naming patterns

### Alert Thresholds

- Start with conservative thresholds and adjust based on data
- Use multiple severity levels (warning, critical)
- Include meaningful descriptions and runbooks

### Dashboard Design

- Group related metrics together
- Use consistent time ranges across panels
- Include template variables for filtering
- Add helpful annotations and descriptions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your templates/improvements
4. Test compilation and functionality
5. Submit a pull request

### Adding New Templates

1. Create your template in the appropriate directory
2. Follow existing naming conventions
3. Include documentation comments
4. Add usage examples
5. Test thoroughly

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: General questions and discussions via GitHub Discussions
- **Documentation**: Additional docs in the `/docs` directory

## 🙏 Acknowledgments

- Inspired by SRE and observability best practices
- Built on the foundation of Prometheus and Grafana ecosystems
- Community contributions and feedback