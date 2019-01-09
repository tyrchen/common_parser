defmodule CommonParser.Expr do
  @moduledoc """
  Documentation for Parser.
  """
  import NimbleParsec
  import CommonParser.Helper

  # tag := ascii_tag_with_space([?a..?z])
  # single_value := string_with_quote | integer | atom_with_space
  # list_value := [ single_value | single_value , single_value ]
  # value := single_value | list_value

  # op1 := = | in | not in
  # op2 := < | <= | > | >=
  # op3 := and | or

  # cond1 := ( tag op1 value )
  # cond2 := ( tag op2 integer )

  # sub_expr := ( cond1 | cond2 )
  # expr := sub_expr op3 expr | sub_expr

  tag = ascii_tag_with_space() |> reduce({:parser_result_to_atom, []})
  single_value = choice([string_with_space(), integer_with_space(), atom_with_space()])

  defcombinatorp :list_entries,
                 choice([
                   single_value
                   |> concat(ignore_sep(","))
                   |> concat(parsec(:list_entries)),
                   single_value
                 ])

  list_value =
    ignore_space()
    |> ignore(string("["))
    |> concat(ignore_space())
    |> parsec(:list_entries)
    |> concat(ignore_space())
    |> ignore(string("]"))
    |> concat(ignore_space())
    |> reduce({Enum, :uniq, []})

  value = choice([single_value, list_value]) |> unwrap_and_tag(:v)
  op1 = ops_with_space(["=", "!=", "in", "not in"]) |> reduce({:parser_result_to_atom, []})
  op2 = ops_with_space(["<", "<=", ">", ">="]) |> reduce({:parser_result_to_atom, []})
  op3 = ops_with_space(["and", "or"]) |> reduce({:parser_result_to_atom, []})

  cond1 = tag |> concat(op1) |> concat(value)
  cond2 = tag |> concat(op2) |> concat(integer_with_space())
  sub_expr = ignore_bracket(?\(, choice([cond1, cond2]), ?\)) |> tag(:expr)

  defcombinatorp :expr,
                 choice([
                   parsec(:expr)
                   |> concat(op3)
                   |> concat(sub_expr),
                   sub_expr
                 ])

  @doc """
  Parse to an atom. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.Expr.parse_atom(":h")
    {:ok, [:h], "", %{}, {1, 0}, 2}
    iex> CommonParser.Expr.parse_atom(":hello_world")
    {:ok, [:hello_world], "", %{}, {1, 0}, 12}
    iex> CommonParser.Expr.parse_atom(":he2llo_world1")
    {:ok, [:he], "2llo_world1", %{}, {1, 0}, 3}

  """

  defparsec :parse_atom, atom_with_space()

  @doc ~S"""
  Parse to a string. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.Expr.parse_quoted_string(~S("hello world"))
    {:ok, ["hello world"], "", %{}, {1, 0}, 13}
    iex> CommonParser.Expr.parse_quoted_string(~S(hello world))
    {:error, "expected byte equal to ?\"", "hello world", %{}, {1, 0}, 0}
    iex> CommonParser.Expr.parse_quoted_string(~S("hello \"world\""))
    {:ok, ["hello \"world\""], "", %{}, {1, 0}, 17}
  """
  defparsec :parse_quoted_string, string_with_space()

  @doc """
  Parse a value

    iex> CommonParser.Expr.parse_value("10")
    {:ok, [v: 10], "", %{}, {1, 0}, 2}
    iex> CommonParser.Expr.parse_value(~S(["a", :a, 1]))
    {:ok, [v: ["a", :a, 1]], "", %{}, {1, 0}, 12}
  """
  defparsec :parse_value, value

  @doc """
  Parse a condition.

    iex> CommonParser.Expr.parse_expr("a != 1")
    {:ok, [expr: [:a, :!=, {:v, 1}]], "", %{}, {1, 0}, 6}
    iex> CommonParser.Expr.parse_expr(~S(a in ["hello", :world, 2]))
    {:ok, [expr: [:a, :in, {:v, ["hello", :world, 2]}]], "", %{}, {1, 0}, 25}
  """
  defparsec :parse_expr, sub_expr

  defparsec :parse, parsec(:expr)
end
