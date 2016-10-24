defmodule LocDrescher.Update.Harvesting do
  require Logger
  import SweetXml
  @subscribed_feeds Application.get_env(:loc_drescher, :subscribed_feeds)

  def start(from) do
    @subscribed_feeds
    |> Enum.map(fn({name, url}) ->
        fetch_feed(url, 1, from)
      end)
  end

  def fetch_feed(url, index, from) do
    { relevant_changes, old_changes } =
      "#{url}#{index}"
      |> start_query
      |> handle_response
      |> xpath(~x"//entry"l)
      |> Enum.map(fn(entry) ->
          %{
            updated: entry |> xpath(~x"./updated/text()"),
            link: entry |> xpath(~x"./link[@type='application/marc+xml']/@href")
          }
        end)
      |> Enum.split_while(fn(%{updated: updated, link: link}) ->
          updated
          |> to_string
          |> Timex.parse!("%FT%T%:z", :strftime)
          |> Timex.after?(from)
        end)
      |> IO.inspect

      relevant_changes
      |> Enum.map(fn(link: link} ->
          start_query(link)
        end)
      |> handle_response
      |> IO.inspect
      # Async: fetch entries

      next_feed?(index + 1, from, url, old_changes)
  end

  defp next_feed?(index, from, url,  []) do
    fetch_feed(index, from, url)
  end

  defp next_feed?(_index, _from, _url, _old_changes) do
    { :ok, "top!" }
  end

  defp start_query(url) do
    url # application/atom+xml
    |> HTTPoison.get#(%{"Accept" => "application/atom+xml"})
  end

  defp handle_response({ :ok, %HTTPoison.Response{ status_code: 200, body: body} } ) do
    body
  end

  defp handle_response({ :ok, %HTTPoison.Response{
      status_code: 404,
      body: _body,
      headers: _headers} } ) do
    { :error, 404 }
  end

  defp handle_response({:ok, %HTTPoison.Response{
      status_code: 403,
      body: _body,
      headers: _headers} } ) do
    { :error, 403 }
  end

  defp handle_response({ :ok, %HTTPoison.Response{
      status_code: 500,
      body: body,
      headers: headers} } ) do
    Logger.error "Status code 500 in response."
    Logger.error "Headers:"
    Logger.error  headers
    Logger.error "Body:"
    Logger.error  body
    Logger.error "Stopping script..."

    System.halt(0)
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}} ) do
    Logger.error "HTTPoison error."
    IO.inspect reason

    System.halt(0)
  end
end
