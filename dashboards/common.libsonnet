local grafonnet = import 'grafonnet/main.libsonnet';
local ts = grafonnet.panel.timeSeries;
local barChart = grafonnet.panel.barChart;
local barGauge = grafonnet.panel.barGauge;
local heatmap = grafonnet.panel.heatmap;
local table = grafonnet.panel.table;
local var = grafonnet.dashboard.variable;

{
  /**
   * Declare common panel options
   *
   * For the panels we configure, we want:
   * - Y axes to start from 0            -- withMin(0)
   * - Legend tooltip to show all values -- withTooltip({mode: 'multi'})
   *
   * ref: https://grafana.com/docs/grafana/v10.4/panels-visualizations/configure-panel-options/
   */

  // grafana ref:   https://grafana.com/docs/grafana/v10.4/panels-visualizations/visualizations/time-series/
  // grafonnet ref: https://grafana.github.io/grafonnet/API/panel/timeSeries/index.html
  tsOptions:
    ts.standardOptions.withMin(0)
    + ts.options.withTooltip({ mode: 'multi' }),

  // grafana ref:   https://grafana.com/docs/grafana/v10.4/panels-visualizations/visualizations/bar-chart/
  // grafonnet ref: https://grafana.github.io/grafonnet/API/panel/barChart/index.html
  barChartOptions:
    barChart.standardOptions.withMin(0)
    + barChart.options.withTooltip({ mode: 'multi' }),

  // grafana ref:   https://grafana.com/docs/grafana/v10.4/panels-visualizations/visualizations/bar-gauge/
  // grafonnet ref: https://grafana.github.io/grafonnet/API/panel/barGauge/index.html
  barGaugeOptions:
    barGauge.standardOptions.withMin(0),

  // grafana ref:   https://grafana.com/docs/grafana/v10.4/panels-visualizations/visualizations/heatmap/
  // grafonnet ref: https://grafana.github.io/grafonnet/API/panel/heatmap/index.html
  heatmapOptions:
    heatmap.standardOptions.withMin(0),

  tableOptions:
    table.standardOptions.withMin(0),


  variables: {
    prometheus:
      var.datasource.new('PROMETHEUS_DS', 'prometheus'),
    hub:
      var.query.new('hub')
      + var.query.withDatasourceFromVariable(self.prometheus)
      + var.query.withRefresh('time')
      + var.query.selectionOptions.withMulti()
      + var.query.selectionOptions.withIncludeAll()
      + var.query.queryTypes.withLabelValues('namespace', 'kube_service_labels{service="hub"}'),
    user_pod:
      var.query.new('user_pod')
      + var.query.withDatasourceFromVariable(self.prometheus)
      + var.query.withRefresh('time')
      + var.query.selectionOptions.withMulti()
      + var.query.selectionOptions.withIncludeAll()
      + var.query.queryTypes.withLabelValues('pod', 'kube_pod_labels{label_app="jupyterhub", label_component="singleuser-server", namespace=~"$hub"}'),
    // Queries should use the 'instance' label when querying metrics that
    // come from collectors present on each node - such as node_exporter or
    // container_ metrics, and use the 'node' label when querying metrics
    // that come from collectors that are present once per cluster, like
    // kube_state_metrics.
    instance:
      var.query.new('instance')
      + var.query.withDatasourceFromVariable(self.prometheus)
      + var.query.withRefresh('time')
      + var.query.selectionOptions.withMulti()
      + var.query.selectionOptions.withIncludeAll()
      + var.query.queryTypes.withLabelValues('node', 'kube_node_info'),
  },

  _nodePoolLabelKeys: [
    'label_alpha_eksctl_io_nodegroup_name',  // EKS done via eksctl sets this label
    'label_cloud_google_com_gke_nodepool',  // GKE sets this label
    'label_kubernetes_azure_com_agentpool',  // AKS sets this label
  ],

  /**
   * List of labels applied onto nodes describing the nodegroup they belong to.
   * This is different per cloud provider, so we list them all here. Prometheus will just ignore
   * the labels that are not present.
   */
  nodePoolLabels: std.join(', ', self._nodePoolLabelKeys),

  /**
   * Legend used to display name of nodepool a timeseries belongs to, to be used in conjunction with
   * nodePoolLabels. Grafana will ignore all the labels that don't exist, and we will get to see a
   * human readable name of the nodepool in question.
   */
  nodePoolLabelsLegendFormat: '{{' + std.join('}}{{', self._nodePoolLabelKeys) + '}}',
}
