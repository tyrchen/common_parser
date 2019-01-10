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

  tag = parse_tag() |> reduce({:parser_result_to_atom, []})
  single_value = choice([parse_string(), parse_integer(), parse_atom()])

  defcombinatorp :list_entries,
                 choice([
                   single_value
                   |> concat(ignore_space())
                   |> concat(ignore_sep(","))
                   |> concat(ignore_space())
                   |> concat(parsec(:list_entries)),
                   single_value
                 ])

  list_value =
    ignore(string("["))
    |> concat(ignore_space())
    |> parsec(:list_entries)
    |> concat(ignore_space())
    |> ignore(string("]"))
    |> reduce({Enum, :uniq, []})

  value = choice([single_value, list_value]) |> unwrap_and_tag(:v)
  op1 = parse_ops(["=", "!=", "in", "not in"]) |> reduce({:parser_result_to_atom, []})
  op2 = parse_ops(["<", "<=", ">", ">="]) |> reduce({:parser_result_to_atom, []})
  op3 = parse_ops(["and", "or"]) |> reduce({:parser_result_to_atom, []})

  cond1 = tag |> concat(ignore_space()) |> concat(op1) |> concat(ignore_space()) |> concat(value)

  cond2 =
    tag
    |> concat(ignore_space())
    |> concat(op2)
    |> concat(ignore_space())
    |> concat(parse_integer())

  sub_expr = ignore_bracket(?\(, choice([cond1, cond2]), ?\))

  defcombinatorp :expr,
                 choice([
                   sub_expr
                   |> concat(ignore_space())
                   |> concat(op3)
                   |> concat(ignore_space())
                   |> concat(ignore_bracket(?\(, parsec(:expr), ?\)))
                   |> tag(:expr),
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

  defparsec :parse_atom, parse_atom()

  @doc ~S"""
  Parse to a string. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.Expr.parse_quoted_string(~S("hello world"))
    {:ok, ["hello world"], "", %{}, {1, 0}, 13}

    iex> CommonParser.Expr.parse_quoted_string(~S(hello world))
    {:error, "expected byte equal to ?\"", "hello world", %{}, {1, 0}, 0}

    iex> CommonParser.Expr.parse_quoted_string(~S("hello \"world\""))
    {:ok, ["hello \"world\""], "", %{}, {1, 0}, 17}
  """
  defparsec :parse_quoted_string, parse_string()

  @doc """
  Parse a value. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.Expr.parse_value("10")
    {:ok, [v: 10], "", %{}, {1, 0}, 2}

    iex> CommonParser.Expr.parse_value(~S(["a", :a, 1]))
    {:ok, [v: ["a", :a, 1]], "", %{}, {1, 0}, 12}
  """
  defparsec :parse_value, value

  @doc """
  Parse a sub expr. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.Expr.parse_expr("a != 1")
    {:ok, [:a, :!=, {:v, 1}], "", %{}, {1, 0}, 6}

    iex> CommonParser.Expr.parse_expr(~S(a in ["hello", :world, 2]))
    {:ok, [:a, :in, {:v, ["hello", :world, 2]}], "", %{}, {1, 0}, 25}
  """
  defparsec :parse_expr, sub_expr

  @doc ~S"""
  Parse an expression.

    iex> CommonParser.Expr.parse("a=1 and b = 2")
    {:ok, [expr: [:a, :==, {:v, 1}, :and, :b, :==, {:v, 2}]], "", %{}, {1, 0}, 13}

    iex> CommonParser.Expr.parse("a=1 and b in [\"abc\", :abc, 123]")
    {:ok, [expr: [:a, :==, {:v, 1}, :and, :b, :in, {:v, ["abc", :abc, 123]}]], "", %{}, {1, 0}, 31}

    iex> CommonParser.Expr.parse("a=1 and (b in [\"abc\", :abc, 123] or c != [1,2,3])")
    {:ok, [expr: [:a, :==, {:v, 1}, :and, {:expr, [:b, :in, {:v, ["abc", :abc, 123]}, :or, :c, :!=, {:v, [1, 2, 3]}]}]], "", %{}, {1, 0}, 49}

  """
  defparsec :parse, parsec(:expr)
end
