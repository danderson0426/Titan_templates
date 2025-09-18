# Migration Guide: Custom Grafana Library to Grafonnet

This guide explains when and how to migrate from the custom `grafana.libsonnet` library to the Grafonnet integration library.

## When to Use Each Library

### Custom Grafana Library (`grafana.libsonnet`)
**Use when:**
- Simple, standalone dashboards
- Learning Jsonnet and Grafana concepts
- Environment constraints prevent Grafonnet installation
- Need basic panel creation without extensive customization

**Limitations:**
- Limited panel types and options
- Manual dashboard composition
- No integration with alert management
- Basic template variable support

### Grafonnet Integration (`grafonnet.libsonnet`)  
**Use when:**
- Production environments requiring robust monitoring
- Need integrated alerts and dashboards
- Team standardization across multiple services
- Complex dashboard requirements
- SLO monitoring and burn rate alerts

**Advantages:**
- Industry-standard Grafonnet compatibility
- Integrated alert and dashboard generation  
- Rich template and query library
- SLO-focused layouts and panels
- Comprehensive monitoring patterns

## Migration Examples

### Before: Custom Grafana Library

```jsonnet
local grafana = import 'jsonnet/lib/grafana.libsonnet';
local prometheus = import 'jsonnet/lib/prometheus.libsonnet';

// Separate alert rules
local alerts = [
  prometheus.alerts.serviceDown('api_down', filters={job: 'api'}),
];

// Manual dashboard creation
local panels = [
  grafana.panels.timeSeries('Request Rate', [{
    expr: 'sum(rate(http_requests_total{job="api"}[5m]))',
    legendFormat: 'Requests/sec',
    refId: 'A',
  }], 'reqps'),
  
  grafana.panels.stat('Error Rate', [{
    expr: 'sum(rate(http_requests_total{job="api",code=~"5.."}[5m])) / sum(rate(http_requests_total{job="api"}[5m])) * 100',
    refId: 'A',
  }], 'percent', [1, 5]),
];

// Separate outputs
{
  alerts: prometheus.prometheusRule('api-monitoring', 'monitoring', [{
    name: 'api-alerts',
    rules: alerts,
  }]),
  dashboard: grafana.dashboard('API Dashboard', panels=panels),
}
```

### After: Grafonnet Integration

```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

// One-line complete monitoring setup
grafonnet.integration.monitoring('api', 'production', 'platform')
```

**Results in:**
- Same alert rules automatically generated
- 6-panel dashboard with service health, request rate, error rate, latency, CPU, and memory
- Template variables for service and instance filtering
- Consistent styling and thresholds

## Step-by-Step Migration

### 1. Assess Current Usage

**Inventory your current dashboards:**
```bash
# Find all custom grafana library usage
grep -r "grafana\.panels\|grafana\.dashboard" jsonnet/
```

**Identify patterns:**
- Which panels are most commonly used?
- Are alerts and dashboards created separately?
- What customizations exist?

### 2. Simple Migration

**Replace basic panels:**

```jsonnet
// Old
grafana.panels.timeSeries('Request Rate', targets, 'reqps')

// New  
grafonnet.panelTemplates.requestRate('Request Rate', 'my-service')
```

**Replace dashboard creation:**

```jsonnet
// Old
grafana.dashboard('My Dashboard', panels=myPanels)

// New
grafonnet.dashboards.monitoring('My Dashboard', 'my-service')
```

### 3. Advanced Migration

**Add integrated monitoring:**

```jsonnet
// Replace separate alert and dashboard files
local monitoring = grafonnet.integration.monitoring(
  'my-service',
  'production',
  'my-team',
  { availability: 99.9, error_rate: 0.5 }
);

{
  prometheusRule: monitoring.prometheusRule,
  dashboard: monitoring.dashboard,
}
```

**Extend with custom panels:**

```jsonnet
local grafonnet = import 'jsonnet/lib/grafonnet.libsonnet';

// Start with standard layout
local standardPanels = grafonnet.layouts.monitoring('my-service');

// Add custom business panels
local businessPanels = [
  grafonnet.panelTemplates.requestRate('Business Transactions', 'my-service') + {
    targets: [{
      expr: 'sum(rate(business_transactions_total[5m])) by (type)',
      legendFormat: '{{type}}',
      refId: 'A',
    }],
    gridPos: { h: 8, w: 24, x: 0, y: 16 },
  },
];

// Create enhanced dashboard
grafonnet.dashboards.monitoring('My Service', 'my-service') + {
  dashboard+: {
    panels: standardPanels + businessPanels,
  },
}
```

## Compatibility Matrix

| Feature | Custom Grafana | Grafonnet Integration |
|---------|----------------|----------------------|
| Basic panels | ✅ | ✅ |
| Template variables | Basic | ✅ Advanced |
| Alert integration | Manual | ✅ Automatic |
| SLO monitoring | ❌ | ✅ |
| Panel positioning | Manual | ✅ Automatic |
| Industry standard | ❌ | ✅ |
| Learning curve | Low | Medium |
| Maintenance | High | Low |

## Migration Checklist

- [ ] **Assess current dashboards** - inventory usage patterns
- [ ] **Install prerequisites** - Grafonnet library if using actual Grafonnet
- [ ] **Start with simple services** - migrate basic monitoring first
- [ ] **Test in development** - validate dashboard generation
- [ ] **Update CI/CD** - modify build scripts for new library
- [ ] **Train team** - document new patterns and examples  
- [ ] **Migrate gradually** - service by service migration
- [ ] **Remove old patterns** - clean up custom grafana usage

## Common Pitfalls

### 1. Panel ID Conflicts
**Problem:** Manually assigned panel IDs conflict with auto-generated ones

**Solution:** Let Grafonnet manage panel IDs automatically
```jsonnet
// Avoid manual ID assignment
// panel + { id: 42 }

// Let the library handle it
grafonnet.layouts.monitoring('service')
```

### 2. Grid Position Overlaps
**Problem:** Custom panels overlap with standard layout

**Solution:** Use proper grid positioning
```jsonnet
customPanel + { 
  gridPos: { h: 8, w: 12, x: 0, y: 16 }  // Start after standard panels
}
```

### 3. Query Compatibility
**Problem:** Existing queries don't work with new panels

**Solution:** Use the query library or adapt existing queries
```jsonnet
// Use built-in queries
grafonnet.queries.requestRate('my-service')

// Or adapt existing
customPanel + {
  targets: [{ expr: 'my_custom_query', refId: 'A' }]
}
```

## Getting Help

1. **Check examples** - Review `jsonnet/examples/grafonnet-*.jsonnet`
2. **Use templates** - Start with `jsonnet/templates/grafonnet-web-service-monitoring.jsonnet`
3. **Read documentation** - See `docs/grafonnet-guide.md`
4. **Test incrementally** - Validate each step with `jsonnet --jpath jsonnet/lib`

## Next Steps

After migration:
1. **Standardize monitoring** across all services using patterns
2. **Implement SLO monitoring** using built-in templates  
3. **Automate dashboard generation** in CI/CD pipelines
4. **Share templates** with other teams
5. **Contribute improvements** back to the library