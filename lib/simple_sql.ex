defmodule CommonParser.SimpleSql do
  @moduledoc """
  SQL parser

  a sql: select * from account_state where balance > 100

  # tag := ascii_string([?a..?z], min: 1)
  # tag_list := tag | tag , tag
  # selector := * | tag_list
  # condition := expr
  # sql := select selector from tag where condition
  """

  import NimbleParsec
  import CommonParser.Helper

  tag = ascii_tag_with_space()

  defcombinatorp :tag_list,
                 choice([
                   tag
                   |> concat(ignore_sep(","))
                   |> concat(parsec(:tag_list)),
                   tag
                 ])

  defcombinatorp :selector,
                 ignore_keyword("select")
                 |> concat(
                   choice([
                     string("*"),
                     parsec(:tag_list)
                   ])
                 )
                 |> concat(ignore_space())
                 |> reduce({Enum, :uniq, []})
                 |> unwrap_and_tag(:select)

  from =
    ignore_keyword("from") |> concat(tag) |> reduce({:parser_result_to_atom, []}) |> tag(:from)

  condition = ascii_string([], min: 1) |> tag(:where)

  # for where condition, we don't allow
  where_cond =
    ignore_keyword("where")
    |> concat(condition)
    |> optional()

  sql = parsec(:selector) |> concat(from) |> concat(where_cond)

  @doc """
  parse `select` statement. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.SimpleSql.parse_select("select *")
    {:ok, [select: ["*"]], "", %{}, {1, 0}, 8}
    iex> CommonParser.SimpleSql.parse_select("select a, b, c, a")
    {:ok, [select: ["a", "b", "c"]], "", %{}, {1, 0}, 17}

  """
  defparsec :parse_select, parsec(:selector)

  @doc """
  parse `from` statement. For testing purpose. Please use `parse/2` instead.

    iex> CommonParser.SimpleSql.parse_from("from abc")
    {:ok, [from: [:abc]], "", %{}, {1, 0}, 8}
    iex(4)> CommonParser.SimpleSql.parse_from("from abc, def")
    {:ok, [from: [:abc]], ", def", %{}, {1, 0}, 8}
  """
  defparsec :parse_from, from

  @doc """
  parse a full sql

    iex> CommonParser.SimpleSql.parse("select * from abc where c < 10")
    {:ok, [select: ["*"], from: [:abc], where: ["c < 10"]], "", %{}, {1, 0}, 30}
    iex(7)> CommonParser.SimpleSql.parse(~S(select balance, nonce, num_txs from abc where c < 10 and b not in ["c", "d"]))
    {:ok, [select: ["balance", "nonce", "num_txs"], from: [:abc], where: [~S(c < 10 and b not in ["c", "d"])]], "", %{}, {1, 0}, 76}

  """
  defparsec :parse, sql
end
