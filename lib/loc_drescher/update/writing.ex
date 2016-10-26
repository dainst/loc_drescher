defmodule LocDrescher.Update.Writing do
  require Logger

  import SweetXml

  alias LocDrescher.MARC.{Record, Field}

  @opening_tag ~s(<?xml version="1.0" encoding="UTF-8" ?> \n) <>
  ~s(<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim" ) <>
  ~s(xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ) <>
  ~s(xsi:schemaLocation="http://www.loc.gov/MARC21/slim" ) <>
  ~s(http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" ) <>
  ~s(xmlns:xlink="http://www.w3.org/1999/xlink" ) <>
  ~s(xmlns:mods="http://www.loc.gov/mods/v3" ) <>
  ~s(xmlns:mxe="http://www.loc.gov/mxe" ) <>
  ~s(xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" ) <>
  ~s(xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" ) <>
  ~s(xmlns:skos="http://www.w3.org/2004/02/skos/core#" ) <>
  ~s(xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" ) <>
  ~s(xmlns:ri="http://id.loc.gov/ontologies/RecordInfo#" ) <>
  ~s(xmlns:mets="http://www.loc.gov/METS/"> \n)

  @closing_tag ~s(</marc:collection>)

  def write_item_update(record) do
    { file_pid } = Agent.get(OutputFile, &(&1))

    IO.binwrite(file_pid, record |> marcxml_to_marc)
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
