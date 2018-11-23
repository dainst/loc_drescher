defmodule LocDrescher.Update.Harvesting do
  require Logger

  import SweetXml

  alias LocDrescher.Update.Writing

  @subscribed_feeds Application.get_env(:loc_drescher, :subscribed_feeds)

  def start(date_to) do

    Logger.info("Start date for harvesting: #{date_to}.")

    @subscribed_feeds
    |> Stream.map(fn({key, url}) ->
        Logger.info("Harvesting feed for #{key}.")
        url
      end)
    |> Enum.map(&Task.async(fn -> accumulate_changes(&1, 1, date_to, []) end))
    |> Enum.map(&Task.await(&1, :infinity))
    |> Enum.each(&fetch_marcxml_records(&1))

    {:ok, "Finished harvest."}
  end

  def accumulate_changes(url, index, date_to, changes) do
    Logger.info(~s(Next feed page: #{"#{url}#{index}"}))

    { relevant_changes, old_changes } =
      "#{url}#{index}"
      |> split_feed(date_to)

    updated_changes = changes ++ relevant_changes

    if old_changes == [] do
      accumulate_changes(url, index + 1, date_to, updated_changes)
    else
      Logger.info("Found #{length(updated_changes)} changes for feed #{url}.")
      updated_changes
    end
  end

  defp split_feed(url, requested_date) do
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
    |> Enum.split_with(fn(%{updated: updated, link: link}) ->
        if link == nil do
          Logger.warn "No link type='application/marc+xml' found at #{link}!"
          false
        else

          updated
          |> to_string
          |> String.slice(0..9)
          |> Date.from_iso8601!
          |> later_than_requested_date?(requested_date)
        end
      end)
  end


  defp later_than_requested_date?(feed_date, requested_date) do
    case Date.compare(feed_date, requested_date ) do
      :gt ->
        # IO.inspect("#{feed_date} still later than #{requested_date}")
        true
      _ ->
        # IO.inspect("#{feed_date} earlier than #{requested_date}")
        false
    end
  end

  defp fetch_marcxml_records([]) do
    Logger.debug("No new records for feed.")
  end

  defp fetch_marcxml_records(urls) do
    Logger.info("Retrieving and processing changed MARC XML records. This may take some time...")

    urls
    |> Enum.reverse
    |> Stream.map(fn(%{link: link}) ->
        link
      end)
    |> Enum.map(&Task.async(fn -> start_query(&1, 2) end))
    |> Enum.map(&Task.await(&1, :infinity))
    |> Stream.map(&handle_response(&1))
    |> Enum.map(&Writing.write_item_update(&1))
  end


  defp start_query(url, retry) do
    response =
      url
      |> HTTPoison.get(
           [
             {"Accept","application/xml"},
             {"Cookie", "?"} # Some cookie has to be set in order to retrieve correct data, unclear why.
           ],
           [ timeout: :infinity, recv_timeout: :infinity ])

    {url, response, retry }
  end

  defp handle_response({_url,
    { :ok, %HTTPoison.Response{ status_code: 200, body: body} },
    _retry }) do
    body
  end

  defp handle_response({ url,
    { :ok, %HTTPoison.Response{ status_code: 404, body: _body, headers: _headers} },
    retry }) do

    if(retry > 0) do
      url
      |> start_query(retry - 1)
      |> handle_response
    else
      Logger.error("404 Error for #{url}.")
      { :error, 404 }
    end
  end

  defp handle_response({_url, {:ok, %HTTPoison.Response{
      status_code: 403,
      body: _body,
      headers: _headers} }, _retry }) do
    { :error, 403 }
  end

  defp handle_response({url, { :ok, %HTTPoison.Response{
      status_code: 500,
      body: body,
      headers: headers} }, retry }) do
    if(retry > 0) do
      url
      |> start_query(retry - 1)
      |> handle_response
    else
      Logger.error "Status code 500 in response for #{url}"
      Logger.error "Headers:"
      IO.inspect  headers
      Logger.error "Body:"
      IO.inspect  body
      { :error, 500 }
    end

  end

  defp handle_response({url,
      {:error, error = %HTTPoison.Error{id: nil, reason: :closed}},
      retry}) do
    if(retry > 0) do
      url
      |> start_query(retry - 1)
      |> handle_response
    else
      IO.inspect "HTTPoison error: :closed, no more retries."
      IO.inspect error
      System.halt(0)
    end
  end

  defp handle_response({_url, {:error, message }, _retry}) do
    Logger.error "HTTPoison error."
    IO.inspect message

    System.halt(0)
  end
end
