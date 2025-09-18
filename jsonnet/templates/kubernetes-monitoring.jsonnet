// Example: Kubernetes cluster monitoring template
local prometheus = import '../lib/prometheus.libsonnet';
local utils = import '../lib/utils.libsonnet';

// Configuration
local config = {
  cluster_name: 'production-cluster',
  environment: 'production',
  team: 'platform',
};

// Node-level alerts
local nodeAlerts = [
  // Node down
  {
    alert: 'NodeDown',
    expr: 'up{job="node-exporter"} == 0',
    'for': '5m',
    labels: utils.labels.standard('node_down', config.environment, config.team) + {
      severity: 'critical',
      type: 'infrastructure',
    },
    annotations: {
      summary: 'Node is down',
      description: 'Node {{ $labels.instance }} has been down for more than 5 minutes',
    },
  },

  // High CPU usage
  {
    alert: 'NodeHighCPU',
    expr: '100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80',
    'for': '5m',
    labels: utils.labels.standard('node_high_cpu', config.environment, config.team) + {
      severity: 'warning',
      type: 'resource',
    },
    annotations: {
      summary: 'High CPU usage on node',
      description: 'CPU usage is {{ $value }}% on {{ $labels.instance }}',
    },
  },

  // High memory usage
  {
    alert: 'NodeHighMemory',
    expr: '(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85',
    'for': '5m',
    labels: utils.labels.standard('node_high_memory', config.environment, config.team) + {
      severity: 'warning',
      type: 'resource',
    },
    annotations: {
      summary: 'High memory usage on node',
      description: 'Memory usage is {{ $value }}% on {{ $labels.instance }}',
    },
  },

  // High disk usage
  {
    alert: 'NodeHighDisk',
    expr: '(1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85',
    'for': '5m',
    labels: utils.labels.standard('node_high_disk', config.environment, config.team) + {
      severity: 'warning',
      type: 'resource',
    },
    annotations: {
      summary: 'High disk usage on node',
      description: 'Disk usage is {{ $value }}% on {{ $labels.instance }} for filesystem {{ $labels.mountpoint }}',
    },
  },
];

// Pod-level alerts
local podAlerts = [
  // Pod CrashLooping
  {
    alert: 'PodCrashLooping',
    expr: 'rate(kube_pod_container_status_restarts_total[15m]) * 60 * 15 > 0',
    'for': '5m',
    labels: utils.labels.standard('pod_crash_looping', config.environment, config.team) + {
      severity: 'warning',
      type: 'workload',
    },
    annotations: {
      summary: 'Pod is crash looping',
      description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} is restarting {{ $value }} times per 15 minutes',
    },
  },

  // Pod not ready
  {
    alert: 'PodNotReady',
    expr: 'kube_pod_status_ready{condition="false"} == 1',
    'for': '5m',
    labels: utils.labels.standard('pod_not_ready', config.environment, config.team) + {
      severity: 'warning',
      type: 'workload',
    },
    annotations: {
      summary: 'Pod is not ready',
      description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} has been not ready for more than 5 minutes',
    },
  },
];

// Kubernetes API server alerts
local apiServerAlerts = [
  // API server down
  {
    alert: 'KubernetesAPIServerDown',
    expr: 'up{job="kubernetes-apiservers"} == 0',
    'for': '1m',
    labels: utils.labels.standard('apiserver_down', config.environment, config.team) + {
      severity: 'critical',
      type: 'control_plane',
    },
    annotations: {
      summary: 'Kubernetes API server is down',
      description: 'Kubernetes API server {{ $labels.instance }} is down',
    },
  },

  // High API server latency
  {
    alert: 'KubernetesAPIServerHighLatency',
    expr: 'histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{subresource!="log",verb!~"^(?:CONNECT|WATCH)$"}[5m])) by (verb, resource, subresource, instance, le)) > 1',
    'for': '5m',
    labels: utils.labels.standard('apiserver_high_latency', config.environment, config.team) + {
      severity: 'warning',
      type: 'control_plane',
    },
    annotations: {
      summary: 'High API server latency',
      description: '99th percentile latency for {{ $labels.verb }} {{ $labels.resource }} is {{ $value }} seconds',
    },
  },
];

// Generate PrometheusRule resource
prometheus.prometheusRule(
  'kubernetes-monitoring',
  'monitoring',
  [
    {
      name: 'kubernetes-nodes',
      interval: '30s',
      rules: nodeAlerts,
    },
    {
      name: 'kubernetes-pods',
      interval: '30s',
      rules: podAlerts,
    },
    {
      name: 'kubernetes-apiserver',
      interval: '30s',
      rules: apiServerAlerts,
    },
  ]
)