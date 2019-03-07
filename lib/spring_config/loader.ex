defmodule SpringConfig.Loader do
  @moduledoc """
    Loads the configuration from the ConfigServer
  """
  alias SpringConfig.Loader.YamlLoader
  alias SpringConfig.Loader.RemoteJsonLoader

  def load() do
    :ets.new(:spring_config, [:set, :protected, :named_table])

    otp_app = fetch_config(:otp_app, true, as: :atom)
    path = fetch_config(:path, false, default: "priv/application.yml")

    app_name =
      fetch_config(:app_name, false,
        default: fn -> SpringConfig.get!(:"spring.application.name") end
      )

    profile = fetch_config(:profile, true)

    YamlLoader.load(
      app: otp_app,
      path: path,
      profile: profile,
      ets_table: :spring_config
    )

    remote_uri_key =
      fetch_config(:remote_uri_key, false, default: :"spring.cloud.config.uri", as: :atom)

    remote_uri =
      fetch_config(:remote_uri, false, default: fn -> SpringConfig.get!(remote_uri_key) end)

    RemoteJsonLoader.load(
      host: remote_uri,
      app_name: app_name,
      profile: profile,
      ets_table: :spring_config
    )
  end

  defp fetch_config(key, required, opts \\ []) do
    value =
      case Application.fetch_env(:spring_config, key) do
        {:ok, {:system, env_key, default}} ->
          System.get_env(env_key) || default

        {:ok, {:system, env_key}} ->
          System.get_env(env_key) || raise "Missing #{env_key} environment variable"

        {:ok, value} ->
          value

        :error ->
          default = opts[:default]

          cond do
            required ->
              raise "Missing required key #{key}"

            is_function(default, 0) ->
              default.()

            true ->
              default
          end
      end

    convert(value, Keyword.get(opts, :as, :string))
  end

  defp convert(value, :string) do
    to_string(value)
  end

  defp convert(value, :atom) when is_atom(value) do
    value
  end

  defp convert(value, :atom) do
    value |> to_string() |> String.to_atom()
  end

  defp convert(value, :integer) when is_integer(value) do
    value
  end

  defp convert(value, :integer) do
    value |> to_string() |> String.to_integer()
  end

  defp convert(value, :float) when is_float(value) do
    value
  end

  defp convert(value, :float) do
    value |> to_string() |> String.to_float()
  end
end