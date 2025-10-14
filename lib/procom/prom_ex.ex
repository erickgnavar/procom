defmodule Procom.PromEx do
  @moduledoc false

  use PromEx, otp_app: :procom

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: ProcomWeb.Router, endpoint: ProcomWeb.Endpoint}
      # Plugins.Ecto,
      # Plugins.Oban,
      # Plugins.PhoenixLiveView,
      # Plugins.Absinthe,
      # Plugins.Broadway,

      # Add your own PromEx metrics plugins
      # Procom.Users.PromExPlugin
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"}
      # {:prom_ex, "ecto.json"},
      # {:prom_ex, "oban.json"},
      # {:prom_ex, "phoenix_live_view.json"},
      # {:prom_ex, "absinthe.json"},
      # {:prom_ex, "broadway.json"},

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:procom, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end
