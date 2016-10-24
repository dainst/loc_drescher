defmodule LocDrescher.CLI do
  require Logger

  alias LocDrescher.Update

  @default_output_files Application.get_env(:loc_drescher, :default_output_files)
  @last_update_info Application.get_env(:loc_drescher, :last_update_info)

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
        start_update(@default_output_files[:update], days_offset)
      _ ->
        print_help
    end
  end

  defp start_update(file_path, days_offset) do
    output_file_pid =
      file_path
      |> open_output_file

    Agent.start(fn ->
      { output_file_pid }
    end, name: OutputFile)

    Update.Writing.open_xml(output_file_pid)

    case File.read(@last_update_info) do
      {:ok, content} ->
        content
        |> Timex.parse("{ISO:Extended}")
        |> extend_timeframe?(days_offset)
        |> Update.Harvesting.start
      _ ->
        Timex.shift(Timex.now, days: -days_offset)
        |> Update.Harvesting.start
    end

    Update.Writing.close_xml(output_file_pid)
    # log_time
  end

  defp open_output_file(file) do
    file
      |> Path.dirname
      |> File.mkdir_p!

    file
      |> File.open!([:write, :utf8])
  end

  defp extend_timeframe?({:ok, last_update}, requested_offset) do
    request = Timex.shift(Timex.now, days: -requested_offset)
    case Timex.before?(last_update, request) do
      true -> last_update
      false -> request
    end
  end

  defp extend_timeframe?({:error, message}, requested_offset) do
    Logger.error "failed to parse #{@last_update_info}:"
    Logger.error message
    Logger.error "requested offset was #{requested_offset}"
    System.halt()
  end

  defp log_time do
    file_pid = open_output_file(@last_update_info)
    IO.binwrite file_pid, Timex.format(Timex.now, "{ISO:Extended}")
  end

  defp print_help() do
    u = @default_output_files[:update]

    IO.puts "Usage: "
    IO.puts "1) ./loc_drescher update [options]"
    IO.puts "         -d | --days <number> (required, the number of days back" <>
            " still considered for the running update )"
    IO.puts "         -t | --target <output path> (optional, defaults to #{u})"
    System.halt(0)
  end
end
