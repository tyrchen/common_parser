defmodule CommonParser.Helper do
  @moduledoc """
  Helper functions for making parser work easy
  """
  import NimbleParsec

  @doc """
  Ignore white space and tab, and make it optional
  """
  @spec ignore_space() :: NimbleParsec.t()
  def ignore_space do
    ascii_string([?\s, ?\t], min: 1)
    |> ignore()
    |> optional()
  end

  @doc """
  Ignore separator and allow spaces before and after separator, e.g. ",", " ,", " , ", etc.
  """
  @spec ignore_sep(binary()) :: NimbleParsec.t()
  def ignore_sep(sep) do
    ignore_space()
    |> ignore(string(sep))
    |> concat(ignore_space())
  end

  def ignore_bracket(left, parser, right) do
    ignore_space()
    |> ignore(ascii_char([left]) |> optional())
    |> concat(parser)
    |> ignore(ascii_char([right]) |> optional())
  end

  @doc """
   Ignore both lowercase name and uppercase name, e.g. " select" / "SELECT    "
  """
  @spec ignore_keyword(binary()) :: NimbleParsec.t()
  def ignore_keyword(name) do
    upper = String.upcase(name)
    lower = String.downcase(name)

    ignore_space()
    |> ignore(choice([string(upper), string(lower)]))
    |> concat(ignore_space())
  end

  @doc """
  match a ascii tag with space. The tag will start with a..z, and followed by "a..z and _", e.g. "hello_world"
  """
  @spec ascii_tag_with_space(list()) :: NimbleParsec.t()
  def ascii_tag_with_space(range \\ [?a..?z, ?_]) do
    ignore_space()
    |> concat(ascii_tag(range))
    |> concat(ignore_space())
  end

  @doc """
  We fixed the 1st char must be a-z, so for opts if min/max is given, please consider to shift with 1.
  """
  @spec ascii_tag(list()) :: NimbleParsec.t()
  def ascii_tag(range) do
    ascii_string([?a..?z], max: 1)
    |> optional(ascii_string(range, min: 1))
    |> reduce({:parser_result_to_string, []})
  end

  # basic types

  @doc """
  Match integer
  """
  @spec integer_with_space() :: NimbleParsec.t()
  def integer_with_space do
    ignore_space()
    |> integer(min: 1)
    |> concat(ignore_space())
  end

  @doc """
  Match string with quote, and inner quote, e.g. ~S("this is \"hello world\"")
  """
  @spec string_with_space() :: NimbleParsec.t()
  def string_with_space do
    ignore_space()
    |> ignore(ascii_char([?"]))
    |> repeat_while(
      choice([
        ~S(\") |> string() |> replace(?"),
        utf8_char([])
      ]),
      {:parser_result_not_quote, []}
    )
    |> ignore(ascii_char([?"]))
    |> concat(ignore_space())
    |> reduce({List, :to_string, []})
  end

  @doc """
  Match an atom with space
  """
  @spec atom_with_space(list()) :: NimbleParsec.t()
  def atom_with_space(range \\ [?a..?z, ?_]) do
    ignore_space()
    |> ignore(ascii_char([?:]))
    |> concat(ascii_tag(range))
    |> concat(ignore_space())
    |> reduce({:parser_result_to_atom, []})
  end

  def ops_with_space(ops) do
    ignore_space()
    |> choice(Enum.map(ops, fn op -> op_replace(op) end))
    |> concat(ignore_space())
  end

  def parser_result_not_quote(<<?", _::binary>>, context, _, _), do: {:halt, context}
  def parser_result_not_quote(_, context, _, _), do: {:cont, context}

  def parser_result_to_string([start]), do: start
  def parser_result_to_string([start, rest]), do: start <> rest
  def parser_result_to_atom([v]), do: String.to_atom(v)

  # private function
  defp op_replace("=" = op), do: string(op) |> replace("==")
  defp op_replace(op), do: string(op)
end
