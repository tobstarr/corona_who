defmodule CoronaWHO do
  def example(countries \\ ["Italy", "Germany", "United States of America"]) do
    cases_by_country()
    |> (fn {:ok, list} -> list end).()
    |> Enum.flat_map(fn res = %{name: name} ->
      if name in countries do
        [res]
      else
        []
      end
    end)
    |> Enum.map(fn %{code: code, name: name} ->
      with {:ok, stats} <- country(code) do
        stats
        |> Enum.take(-10)
        |> with_deltas(name)
      else
        _ ->
          ""
      end
    end)
    |> Enum.join("\n")
    |> IO.write()
  end

  def with_deltas(list, title) do
    case list do
      {:ok, list} ->
        with_deltas(title, list)

      list when is_list(list) ->
        list
        |> Enum.sort_by(& &1.date_of_data_entry, DateTime)
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [prev, current] ->
          delta = (current.confirmed - prev.confirmed) / current.confirmed

          [
            current.date_of_data_entry |> DateTime.to_date(),
            current.confirmed,
            (100 * delta) |> Float.round(2)
          ]
        end)
        |> TableRex.Table.new(~w|date confirmed growth|)
        |> TableRex.Table.put_title(title)
        |> TableRex.Table.render!()

      err ->
        {:error, err}
    end
  end

  def country(code) do
    params = %{
      "cacheHint" => "true",
      "f" => "json",
      "orderByFields" => "DateOfDataEntry asc",
      "outFields" => "OBJECTID,cum_conf,DateOfDataEntry",
      "resultOffset" => "0",
      "resultRecordCount" => "2000",
      "returnGeometry" => "false",
      "spatialRel" => "esriSpatialRelIntersects",
      "where" => "ADM0_NAME='#{code}'"
    }

    uri =
      "https://services.arcgis.com/5T5nSi527N4F7luB/arcgis/rest/services/COVID_19_HistoricCasesByCountry(pt)View/FeatureServer/0/query?#{
        URI.encode_query(params)
      }"

    case load(uri) do
      {:ok, %{features: list}} ->
        {:ok,
         list
         |> Enum.map(fn %{attributes: %{date_of_data_entry: date, cum_conf: cnt}} ->
           %{date_of_data_entry: DateTime.from_unix!(date, :millisecond), confirmed: cnt}
         end)}

      err ->
        {:error, err}
    end
  end

  def cases_by_country do
    params = %{
      "cacheHint" => "true",
      "f" => "json",
      "orderByFields" => "cum_conf desc",
      "outFields" => "*",
      "resultOffset" => "0",
      "resultRecordCount" => "250",
      "returnGeometry" => "false",
      "spatialRel" => "esriSpatialRelIntersects",
      "where" => "1=1"
    }

    uri =
      "https://services.arcgis.com/5T5nSi527N4F7luB/arcgis/rest/services/COVID_19_CasesByCountry(pl)_VIEW/FeatureServer/0/query?#{
        URI.encode_query(params)
      }"

    with {:ok, %{features: list}} <- load(uri) do
      {:ok,
       list
       |> Enum.map(fn %{attributes: %{ad_m0_name: code, ad_m0_viz_name: name}} ->
         %{code: code, name: name}
       end)}
    end
  end

  def load(uri) do
    res = HTTPoison.get(uri)

    with {:ok, %{body: body, status_code: code}} when code >= 200 and code < 300 <- res,
         {:ok, res} <-
           Jason.decode(body, keys: fn k -> Macro.underscore(k) |> String.to_atom() end) do
      {:ok, res}
    else
      err ->
        {:error, err}
    end
  end
end
