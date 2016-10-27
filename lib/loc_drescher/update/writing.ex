defmodule LocDrescher.Update.Writing do
  require Logger
  import SweetXml
  alias LocDrescher.MARC.{Record, Field}

  def write_item_update({:error, _message}) do
    Logger.error "Received faulty record, skipping write operation."
  end

  def write_item_update(record) do

    file_pids = get_relevant_output_files(record, Agent.get(RequestType, &(&1)))

    marc =
      record
      |> marcxml_to_marc

    file_pids
    |> Enum.each(&IO.binwrite(&1, marc))

  end

  defp get_relevant_output_files(record, {:update}) do
    { tags_to_output } = Agent.get(OutputFile, &(&1))

    tags_to_output
    |> Enum.filter(fn({ tag, path }) ->
        record |> xpath(~x"./marcxml:datafield[@tag='#{tag}']")
      end)
  end

  defp marcxml_to_marc([]) do
    ""
  end

  defp marcxml_to_marc(xml_record) do
    xml_record
    |> xpath(~x"./marcxml:controlfield[@tag='001']/text()")

    record_status =
      xml_record
      |> xpath(~x"./marcxml:leader/text()")
      |> to_string
      |> String.at(5)

    record = %Record{}

    control_fields =
      xml_record
      |> xpath(~x"./marcxml:controlfield"l)
      |> Enum.map(fn(field) ->
          %Field{
            tag: field |> xpath(~x"./@tag"),
            controlfield_value: field |> xpath(~x"./text()")
          }
        end)

    data_fields =
      xml_record
      |> xpath(~x"./marcxml:datafield"l)
      |> Enum.map(fn(field) ->
          %Field{
            tag: field |> xpath(~x"./@tag"),
            i1: field |> xpath(~x"./@ind1"),
            i2: field |> xpath(~x"./@ind2"),
            subfields:
              field
              |> xpath(~x"./marcxml:subfield"l)
              |> Enum.map(fn(subfield) ->
                  code = subfield |> xpath(~x"./@code"s)
                  value = subfield |> xpath(~x"./text()")

                  {String.to_atom(code), value}
                end)
            }
          end)

      record =
        Enum.reduce(control_fields, record, fn(field, record) ->
            Record.add_field(record, field)
          end)

      record =
        Enum.reduce(data_fields, record, fn(field, record) ->
            Record.add_field(record, field)
          end)

      record
      |> Record.to_marc(record_status)
  end
end
