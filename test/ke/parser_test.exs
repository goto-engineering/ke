defmodule Ke.ParserTest do
  import Ke.Parser
  use ExUnit.Case
  doctest Ke.Parser

  test "scalars" do
    assert parse("2") == [2]
    assert parse("2.5") == [2.5]
  end

  test "strings" do
    assert parse(~s/"bob"/) == ["bob"]
    assert parse(~s/"bob man"/) == ["bob man"]
  end

  test "names" do
    assert parse(~s/`bob/) == [:bob]
    assert parse(~s/`"bob man"/) == [:"bob man"]
  end

  test "vars" do
    assert parse(~s/name/) == [{:var, "name"}]
  end

  test "monadic verbs" do
    assert parse("!2") == [:!, 2]
  end

  test "dyadic verbs" do
    assert parse("1+1") == [1, :+, 1]
  end

  test "parses multiple expressions into tree structure" do
    assert parse("no:2;no") == {:code, [
      [{:var, "no"}, :":", 2],
      [{:var, "no"}]
    ]}
    assert parse("no:2;na:6;no*na") == {:code, [
      [{:var, "no"}, :":", 2],
      [{:var, "na"}, :":", 6],
      [{:var, "no"}, :*, {:var, "na"}]
    ]}
  end
end
