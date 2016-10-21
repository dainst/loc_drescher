defmodule LocDrescher.Update.Harvesting do
  require Logger
  import SweetXml
  @names_feed Application.get_env(:loc_drescher, :names_feed)

  def start(from) do
    next_feed(1, from, @names_feed)
  end

  def next_feed(index, from, url) do
    atom_response =
      "#{url}#{index}"
      |> start_query
      |> handle_response

    dates =
      atom_response
      |> xpath(~x"//entry"l)
      |> Enum.map(fn (entry) ->
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
