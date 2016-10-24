defmodule LocDrescher.Update.Writing do
  require Logger

  @opening_tag = ~s(<?xml version="1.0" encoding="UTF-8" ?>
  <marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.loc.gov/MARC21/slim
  http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">)

  @closing_tag = ~s(</marc:collection>)

  defp open_xml(file_pid) do
    IO.binwrite file_pid @opening_tag
  end

  defp close_xml({ :ok, _ }, file_pid) do
    IO.binwrite file_pid @closing_tag
  end

  defp close_xml({ :error, message }) do
    Logger.error "Script stopped with error:"
    Logger.error message
  end
end
