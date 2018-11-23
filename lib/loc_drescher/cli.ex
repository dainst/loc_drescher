defmodule LocDrescher.CLI do
  require Logger

  alias LocDrescher.Update

  @output Application.get_env(:loc_drescher, :output)

  def main(argv) do
    result = argv
      |> parse_args
      |> case do
           { %{ help: true }, _, _ } ->
             print_help()
           { switches, ["update"], _ } ->
             start_update(switches)
           _ ->
             print_help()
         end

    case result do
      {:error, message} ->
        Logger.error(message)
      {:help, message} ->
        Logger.info(message)
      {:ok, message} ->
        log_date()
        Logger.info(message)
     end

  end

  defp parse_args(argv) do
    { switches, argv, errors } =
      OptionParser.parse(argv,
        switches: [
          help: :boolean,
          target: :string,
          days: :integer,
          continue: :boolean
        ],
        aliases: [
          h: :help,
          t: :target,
          d: :days,
          c: :continue
        ]
      )
    { Enum.into(switches, %{}), argv, errors }
  end

  defp start_update(%{ target: target_path, days: days_offset}) do
    initialize_agents(target_path, :update)

    :calendar.local_time()
    |> (fn({date, _time}) -> date end).()
    |> Date.from_erl!
    |> Date.add(-days_offset)
    |> Update.Harvesting.start
  end

  defp start_update(%{ days: days_offset}) do
    start_update(%{target: @output[:default_root], days: days_offset})
  end

  defp start_update( %{ target: target_path, continue: true}) do
    initialize_agents(target_path, :update)

    case File.read(@output[:last_update_info]) do
      {:ok, content} ->
        content
        |> Date.from_iso8601
        |> (fn({:ok, date}) -> date end).()
        |> Update.Harvesting.start
      _ ->
        { :error, message: "No valid date to continue from." }
    end
  end

  defp start_update( %{ continue: true}) do
    start_update(%{target: @output[:default_root], continue: true})
  end

  defp start_update(_) do
    print_help()
  end

  defp initialize_agents(output_path, request_type) do
    file_per_tag =
      @output[request_type]
      |> Enum.map(fn({tag, file_name}) ->
        {tag, "#{output_path}#{file_name}"}
      end)
      |> Enum.map(fn({tag, path}) ->
        {tag, open_output_file(path)}
      end)

    Agent.start(fn -> { file_per_tag } end, name: OutputFile)
    Agent.start(fn -> { request_type } end, name: RequestType)
  end


  defp open_output_file(file) do
    file
      |> Path.dirname
      |> File.mkdir_p!

    file
      |> File.open!([:write, :utf8])
  end

  defp log_date do
    out_str =
      :calendar.universal_time()
      |> (fn({date, _time}) -> date end).()
      |> Date.from_erl!
      |> Date.to_string

    @output[:last_update_info]
    |> open_output_file
    |> IO.binwrite(out_str)
  end

  defp print_help() do
      u = @output[:default_root]

      message =
        """
        Usage:
        1) ./loc_drescher update [options]
            -d | --days <number> (required, the number of days back still considered for the running update )
            -t | --target <output path> (optional, defaults to #{u})
        """
      {:help, message}
  end
end
