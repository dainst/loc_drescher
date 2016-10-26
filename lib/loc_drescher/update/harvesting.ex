defmodule LocDrescher.Update.Harvesting do
  require Logger

  import SweetXml

  alias LocDrescher.Update.Writing

  @subscribed_feeds Application.get_env(:loc_drescher, :subscribed_feeds)

  def start(from) do
    @subscribed_feeds
    |> Stream.map(fn({key, url}) ->
        Logger.info("Harvesting feed for #{key}.")
        url
      end)
    |> Enum.map(&Task.async(fn -> fetch_feed(&1, 1, from) end))
    |> Enum.map(&Task.await(&1, :infinity))
  end

  def fetch_feed(url, index, from) do
    Logger.info ~s(Next page: #{"#{url}#{index}"})
    { relevant_changes, old_changes } =
      "#{url}#{index}"
      |> split_feed(from)

    fetch_marcxml_records(relevant_changes)
    next_feed_page?(index + 1, from, url, old_changes)
  end

  defp split_feed(url, from) do
    url
    |> start_query(2)
    |> handle_response
    |> xpath(~x"//entry"l)
    |> Enum.map(fn(entry) ->
        %{
          updated: entry |> xpath(~x"./updated/text()"),
          link: entry |> xpath(~x"./link[@type='application/marc+xml']/@href")
        }
      end)
    |> Enum.split_while(fn(%{updated: updated, link: link}) ->
        if link == nil do
          Logger.warn "No link type='application/marc+xml' found at #{link}!"
          false
        else
          updated
          |> to_string
          |> Timex.parse!("%FT%T%:z", :strftime)
          |> Timex.after?(from)
        end
      end)
  end

  defp fetch_marcxml_records(urls) do
    urls
    |> Stream.map(fn(%{link: link}) ->
        link
      end)
    |> Enum.map(&Task.async(fn -> start_query(&1, 2) end))
    |> Enum.map(&Task.await(&1, :infinity))
    |> Stream.map(&handle_response(&1))
    |> Enum.map(&Writing.write_item_update(&1))
  end

  defp next_feed_page?(index, from, url,  []) do
    fetch_feed(url, index, from)
  end

  defp next_feed_page?(index, _from, url, _old_changes) do
    Logger.info("Reached old changes, stopping at: #{url}#{index - 1}")
    { :ok, "top!" }
  end

  defp start_query(url, retry) do
    response =
      url # application/atom+xml
      |> HTTPoison.get([], [ timeout: :infinity, recv_timeout: :infinity ])

    {url, response, retry }
  end

  defp handle_response({_url,
      { :ok, %HTTPoison.Response{ status_code: 200, body: body} },
      _retry }) do
    body
  end

  defp handle_response({_url, { :ok, %HTTPoison.Response{
      status_code: 404,
      body: _body,
      headers: _headers} }, _retry }) do
    { :error, 404 }
  end

  defp handle_response({_url, {:ok, %HTTPoison.Response{
      status_code: 403,
      body: _body,
      headers: _headers} }, _retry }) do
    { :error, 403 }
  end

  defp handle_response({_url, { :ok, %HTTPoison.Response{
      status_code: 500,
      body: body,
      headers: headers} }, _retry }) do
    Logger.error "Status code 500 in response."
    Logger.error "Headers:"
    Logger.error  headers
    Logger.error "Body:"
    Logger.error  body
    Logger.error "Stopping script..."

    System.halt(0)
  end

  defp handle_response({url,
      {:error, error = %HTTPoison.Error{id: nil, reason: :closed}},
      retry}) do
    if(retry > 0) do
      url
      |> start_query(retry - 1)
      |> handle_response
    else
      Logger.error "HTTPoison error: :closed, no more retries."
      IO.inspect message
      System.halt(0)
    end
  end

  defp handle_response({_url, {:error, message }, _retry}) do
    Logger.error "HTTPoison error."
    IO.inspect message

    System.halt(0)
  end
end
