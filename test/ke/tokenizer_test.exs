defmodule Ke.TokenizerTest do
  import Ke.Tokenizer
  use ExUnit.Case

  test "scalars" do
    assert parse([]) == nil
    assert parse(["2"]) == 2
    assert parse(["-2"]) == -2
    assert parse(["2.5"]) == 2.5
  end

  test "arrays" do
    assert parse(["11", "-22", "33"]) == [11, -22, 33]
    assert parse(["1.1", "2.2", "3.3"]) == [1.1, 2.2, 3.3]
  end

  test "multi-dimensional arrays" do
    assert parse(~w"( 1 2 3 4 )") == [1, 2, 3, 4]
    assert parse(~w"( 1 ; 2 )") == [1, 2]
    assert parse(~w"( 1 1 ; 2 )") == [[1, 1], 2]
    assert parse(~w"( 1 ; 2 2 )") == [1, [2, 2]]
    assert parse(~w"( 1 2.1 ; 3.5 4 )") == [[1, 2.1], [3.5, 4]]
    assert_raise RuntimeError, fn -> parse(~w"( 1 2 ; 3 4") end # missing )

    assert parse(~w"( 1 1 1 ; 2 2 2 ; 3 3 3 ; 4 4 4 )") == [
      [1, 1, 1],
      [2, 2, 2],
      [3, 3, 3],
      [4, 4, 4]
    ]

    assert parse(~w/( 1 1 ; "bob" ; `tree )/) == [[1, 1], "bob", :tree]
    assert parse(~w/( 1 1 ; ( "bob" ; `tree ) )/) == [[1, 1], ["bob", :tree]]
    assert parse(~w/( 1 1 ; ( 2 2 ; 3 3 ) ; 4 4 )/) == [[1, 1], [[2, 2], [3, 3]], [4, 4]]
    assert parse(["+", "(", "1", "2", ";", "3", "4", ")"]) == [:+, [[1, 2], [3, 4]]]
  end

  test "strings" do
    assert parse(~s/"bob"/) == "bob"
    assert parse(~s/"bob man"/) == "bob man"
  end

  test "names" do
    assert parse(~s/`bob/) == :bob
    assert parse(~s/`"bob man"/) == :"bob man"
  end

  test "vars" do
    assert parse(~s/name/) == {:var, "name"}
  end

  test "monadic verbs" do
    assert parse(["!", "2"]) == [:!, 2]
    assert parse(["~", "2", "3"]) == [:"~", [2, 3]]
  end

  test "dyadic verbs" do
    assert parse(["1", "+", "2"]) == [1, :+, 2]
    assert parse(["1", "2", "+", "1", "3"]) == [[1, 2], :+, [1, 3]]
    assert parse(~w"2 2 2 - 1") == [[2, 2, 2], :-, 1]
    assert parse(~w"2 * 1 2 3") == [2, :*, [1, 2, 3]]
  end

  # Do these need to be an AST tree node for eval or is list fine?
  test "combining verbs" do
    assert parse(["~", "!", "2"]) == [:"~", :!, 2]
    assert parse(["*", "|", "2","3", "1"]) == [:*, :|, [2, 3, 1]]
    assert parse(["1", "+", "!", "2"]) == [1, :+, :!, 2]
  end

  test "parses multiple expressions into tree structure" do
    assert parse(["no", ":", "2", ";", "no"]) == {:code, [
      [{:var, "no"}, :":", 2],
      {:var, "no"}
    ]}
    assert parse(["no", ":", "2", ";", "na", ":", "6", ";", "no", "*", "na"]) == {:code, [
      [{:var, "no"}, :":", 2],
      [{:var, "na"}, :":", 6],
      [{:var, "no"}, :*, {:var, "na"}]
    ]}
  end
end
