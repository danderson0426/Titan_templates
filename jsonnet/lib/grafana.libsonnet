// Grafana dashboard and panel utilities
local utils = import 'utils.libsonnet';

{
  // Panel templates
  panels: {
    // Basic graph panel
    graph(title, targets=[], unit='short', min=null, max=null):: {
      title: title,
      type: 'graph',
      targets: targets,
      yAxes: [
        {
          label: unit,
          min: min,
          max: max,
        },
        {
          show: false,
        },
      ],
      legend: {
        show: true,
        values: false,
        alignAsTable: false,
      },
      nullPointMode: 'null',
      lines: true,
      linewidth: 1,
      points: false,
      pointradius: 2,
      bars: false,
      stack: false,
      percentage: false,
      fill: 1,
      fillGradient: 0,
    },

    // Time series panel (new Grafana format)
    timeSeries(title, targets=[], unit='short', min=null, max=null):: {
      title: title,
      type: 'timeseries',
      targets: targets,
      fieldConfig: {
        defaults: {
          color: {
            mode: 'palette-classic',
          },
          custom: {
            axisLabel: '',
            axisPlacement: 'auto',
            barAlignment: 0,
            drawStyle: 'line',
            fillOpacity: 0,
            gradientMode: 'none',
            hideFrom: {
              legend: false,
              tooltip: false,
              vis: false,
            },
            lineInterpolation: 'linear',
            lineWidth: 1,
            pointSize: 5,
            scaleDistribution: {
              type: 'linear',
            },
            showPoints: 'auto',
            spanNulls: false,
            stacking: {
              group: 'A',
              mode: 'none',
            },
            thresholdsStyle: {
              mode: 'off',
            },
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: 'green',
                value: null,
              },
              {
                color: 'red',
                value: 80,
              },
            ],
          },
          unit: unit,
        },
        overrides: [],
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

    // Single stat panel
    singleStat(title, target, unit='short', thresholds=[]):: {
      title: title,
      type: 'singlestat',
      targets: [target],
      format: unit,
      valueName: 'current',
      valueMaps: [],
      mappingTypes: [],
      rangeMaps: [],
      thresholds: std.join(',', [std.toString(t) for t in thresholds]),
      colorBackground: false,
      colorValue: true,
      colors: [
        utils.format.colors.green,
        utils.format.colors.yellow,
        utils.format.colors.red,
      ],
      sparkline: {
        show: false,
        full: false,
        lineColor: 'rgb(31, 120, 193)',
        fillColor: 'rgba(31, 118, 189, 0.18)',
      },
      gauge: {
        show: false,
        minValue: 0,
        maxValue: 100,
        thresholdMarkers: true,
        thresholdLabels: false,
      },
    },

    // Stat panel (new Grafana format)
    stat(title, targets=[], unit='short', thresholds=[]):: {
      title: title,
      type: 'stat',
      targets: targets,
      fieldConfig: {
        defaults: {
          color: {
            mode: 'thresholds',
          },
          mappings: [],
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: utils.format.colors.green,
                value: null,
              },
            ] + [
              {
                color: if i == std.length(thresholds) - 1 then utils.format.colors.red else utils.format.colors.yellow,
                value: thresholds[i],
              }
              for i in std.range(0, std.length(thresholds) - 1)
            ],
          },
          unit: unit,
        },
        overrides: [],
      },
      options: {
        reduceOptions: {
          values: false,
          calcs: ['lastNotNull'],
          fields: '',
        },
        orientation: 'auto',
        textMode: 'auto',
        colorMode: 'value',
        graphMode: 'area',
        justifyMode: 'auto',
      },
      pluginVersion: '8.0.0',
    },

    // Table panel
    table(title, targets=[], columns=[]):: {
      title: title,
      type: 'table',
      targets: targets,
      columns: columns,
      sort: {
        col: 0,
        desc: true,
      },
      styles: [
        {
          alias: 'Time',
          dateFormat: 'YYYY-MM-DD HH:mm:ss',
          pattern: 'Time',
          type: 'date',
        },
        {
          alias: '',
          colorMode: null,
          colors: [
            'rgba(245, 54, 54, 0.9)',
            'rgba(237, 129, 40, 0.89)',
            'rgba(50, 172, 45, 0.97)',
          ],
          decimals: 2,
          pattern: '/.+/',
          thresholds: [],
          type: 'number',
          unit: 'short',
        },
      ],
    },
  },

  // Target/query templates
  targets: {
    // Prometheus target
    prometheus(expr, legendFormat='', interval=''):: {
      expr: expr,
      format: 'time_series',
      legendFormat: legendFormat,
      interval: interval,
      refId: 'A',
    },

    // Multiple Prometheus targets
    prometheusMulti(queries):: [
      self.prometheus(queries[i].expr, queries[i].legend, queries[i].interval) + { refId: std.char(65 + i) }
      for i in std.range(0, std.length(queries) - 1)
    ],
  },

  // Row template
  row(title, collapsed=false, panels=[]):: {
    title: title,
    type: 'row',
    collapsed: collapsed,
    panels: panels,
  },

  // Complete dashboard template
  dashboard(title, description='', tags=[], panels=[], time_from='now-1h', time_to='now', refresh='30s'):: {
    dashboard: {
      id: null,
      title: title,
      description: description,
      tags: tags,
      style: 'dark',
      timezone: 'browser',
      refresh: refresh,
      time: {
        from: time_from,
        to: time_to,
      },
      timepicker: {
        refresh_intervals: ['5s', '10s', '30s', '1m', '5m', '15m', '30m', '1h', '2h', '1d'],
        time_options: ['5m', '15m', '1h', '6h', '12h', '24h', '2d', '7d', '30d'],
      },
      templating: {
        list: [],
      },
      annotations: {
        list: [],
      },
      panels: [
        panels[i] + {
          id: i + 1,
          gridPos: {
            h: 8,
            w: 12,
            x: (i % 2) * 12,
            y: std.floor(i / 2) * 8,
          },
        }
        for i in std.range(0, std.length(panels) - 1)
      ],
      schemaVersion: 16,
      version: 1,
    },
  },
}