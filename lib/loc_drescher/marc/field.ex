defmodule LocDrescher.MARC.Field do
  defstruct [ :tag, :i1, :i2, :controlfield_value, subfields: [] ]

  alias LocDrescher.MARC.Field

  def to_marc(field = %Field{controlfield_value: nil}) do
    i1 =
      case field.i1 do
        nil -> "#"
        value -> to_string(value)
      end
    i2 =
      case field.i2 do
        nil -> "#"
        value -> to_string(value)
      end

    subfields_as_marc =
      field.subfields
      |> subfields_to_marc("")

    field_as_marc = i1 <> i2 <> subfields_as_marc <> << 30 >>

    { field.tag, to_string(field_as_marc) }
  end

  def to_marc(field = %Field{controlfield_value: value}) do
    { field.tag, to_string(value) <> << 30 >> }
  end

  def subfields_to_marc([], result), do: result

  def subfields_to_marc([{key, value} | tail], result) do
    result = result <> << 31 >> <> Atom.to_string(key) <> to_string(value)
    subfields_to_marc(tail, result)
  end
end
