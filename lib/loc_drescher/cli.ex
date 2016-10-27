defmodule LocDrescher.CLI do
  require Logger

  alias LocDrescher.Update

  @output Application.get_env(:loc_drescher, :output)

  def main(argv) do
    argv
    |> parse_args
    |> validate_request
  end

  defp parse_args(argv) do
    { switches, argv, errors } =
      OptionParser.parse(argv,
        switches: [ help: :boolean,
          target: :string,
          days: :integer],
        aliases:  [ h: :help,
          t: :target,
          d: :days]
      )
    { Enum.into(switches, %{}), argv, errors }
  end

  defp validate_request(argv) do
    case argv do
      { %{ help: true }, _, _ } ->
        print_help
      { %{ target: target_path, days: days_offset}, ["update"], _ } ->
        start_update(target_path, days_offset)
      { %{ days: days_offset}, ["update"], _ } ->
        start_update(@output[:default_root], days_offset)
      _ ->
        print_help
    end
  end

  defp start_update(file_path, days_offset) do
    file_per_tag =
      @output[:update]
      |> Enum.map(fn({tag, file_name}) ->
          {tag, "#{file_path}#{file_name}"}
        end)
      |> Enum.map(fn({tag, path}) ->
          {tag, open_output_file(path)}
        end)
      |> IO.inspect

    Agent.start(fn ->
      { file_per_tag }
    end, name: OutputFile)

    Agent.start(fn ->
      { :update }
    end, name: RequestType)

    case File.read(@output[:last_update_info]) do
      {:ok, content} ->
        content
        |> Timex.parse("{ISO:Extended}")
        |> extend_timeframe?(days_offset)
        |> Update.Harvesting.start
      _ ->
        Timex.shift(Timex.now, days: -days_offset)
        |> Update.Harvesting.start
    end

    log_time
  end

  defp open_output_file(file) do
    file
      |> Path.dirname
      |> File.mkdir_p!

    file
      |> File.open!([:write, :utf8])
  end

  defp extend_timeframe?({:ok, last_update}, requested_offset) do
    request = Timex.shift(Timex.today, days: -requested_offset)
    case Timex.before?(last_update, request) do
      true ->
        Logger.info "Extending offset up to last successful update: " <>
          "Harvesting every change since #{last_update}."
        last_update
      false ->
        Logger.info "Applying requested offset of #{requested_offset} days: " <>
          "Harvesting every change since #{request}."
        request
      default ->
        IO.inspect default
    end
  end

  defp extend_timeframe?({:error, message}, requested_offset) do
    Logger.error "failed to parse #{@output[:last_update_info]}:"
    Logger.error message
    Logger.error "requested offset was #{requested_offset}"
    System.halt()
  end

  defp log_time do
    {:ok, time } = Timex.format(Timex.now, "{ISO:Extended}")

    @output[:last_update_info]
    |> open_output_file
    |> IO.binwrite(time)
  end

  defp print_help() do
    u = @output[:default_root]

    IO.puts "Usage: "
    IO.puts "1) ./loc_drescher update [options]"
    IO.puts "         -d | --days <number> (required, the number of days back" <>
            " still considered for the running update )"
    IO.puts "         -t | --target <output path> (optional, defaults to #{u})"
    System.halt(0)
  end
end
