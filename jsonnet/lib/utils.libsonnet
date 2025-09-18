// Common utility functions for observability pipelines
{
  // Utility functions for creating consistent labels and annotations
  labels: {
    // Create standard labels for observability resources
    standard(name, environment='production', team='platform'):: {
      name: name,
      environment: environment,
      team: team,
      managed_by: 'titan-templates',
    },
    
    // Merge custom labels with standard ones
    withCustom(standard_labels, custom_labels):: standard_labels + custom_labels,
  },

  // Time-related utilities
  time: {
    // Common time ranges for dashboards and alerts
    ranges: {
      last_5m: '5m',
      last_15m: '15m',
      last_30m: '30m',
      last_1h: '1h',
      last_6h: '6h',
      last_12h: '12h',
      last_24h: '24h',
      last_7d: '7d',
      last_30d: '30d',
    },
    
    // Convert time strings to seconds for calculations
    toSeconds(timeStr)::
      local timeMap = {
        's': 1,
        'm': 60,
        'h': 3600,
        'd': 86400,
      };
      local num = std.parseInt(std.substr(timeStr, 0, std.length(timeStr) - 1));
      local unit = std.substr(timeStr, std.length(timeStr) - 1, 1);
      num * timeMap[unit],
  },

  // Formatting utilities
  format: {
    // Format numbers for display
    humanize(value, unit='')::
      if value >= 1000000000 then
        '%.1fG%s' % [value / 1000000000, unit]
      else if value >= 1000000 then
        '%.1fM%s' % [value / 1000000, unit]
      else if value >= 1000 then
        '%.1fK%s' % [value / 1000, unit]
      else
        '%g%s' % [value, unit],
    
    // Standard color palette for charts
    colors: {
      green: '#73BF69',
      red: '#F2495C',
      yellow: '#FF9830',
      blue: '#5794F2',
      purple: '#B877D9',
      orange: '#FF7043',
      gray: '#8E8E93',
    },
  },

  // Validation functions
  validate: {
    // Validate required fields are present
    required(obj, fields)::
      local missing = std.filter(function(field) !std.objectHas(obj, field), fields);
      if std.length(missing) > 0 then
        error 'Missing required fields: ' + std.join(', ', missing)
      else
        true,
    
    // Validate environment is valid
    environment(env)::
      local validEnvs = ['development', 'staging', 'production'];
      if std.count(validEnvs, env) == 0 then
        error 'Invalid environment: ' + env + '. Must be one of: ' + std.join(', ', validEnvs)
      else
        true,
  },
}