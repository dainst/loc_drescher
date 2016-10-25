defmodule LocDrescher.Update.Writing do
  require Logger

  import SweetXml

  @opening_tag ~s(<?xml version="1.0" encoding="UTF-8" ?>) <>
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
  ~s(xmlns:mets="http://www.loc.gov/METS/">)

  @closing_tag ~s(</marc:collection>)

  def open_xml(file_pid) do
    IO.binwrite(file_pid, @opening_tag)
  end

  def write_feed_item(item) do
    item
    |> IO.inspect
  end

  def close_xml(file_pid) do
    IO.binwrite(file_pid, @closing_tag)
  end
end
