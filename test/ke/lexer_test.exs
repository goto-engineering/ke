defmodule Ke.LexerTest do
  import Ke.Lexer
  use ExUnit.Case

  test "transforms string into flat token list" do
    assert lex("") == []
    assert_raise RuntimeError, fn ->
      lex(~s/"Bob/) == "hi"
    end
    assert lex(~s/"Bob"/) == ["\"Bob\""]
    assert lex(~s/name:"Bob";"Hi, ",name/) == ["name", ":", "\"Bob\"", ";", "\"Hi, \"", ",", "name"]
    assert lex("+(1 12;33 3)") == ["+", "(", "1", "12", ";", "33", "3", ")"]
  end

  test "scalars" do
    assert lex("2") == ["2"]
    assert lex("-2") == ["-2"]
    assert lex("2.5") == ["2.5"]
  end

  test "arrays" do
    assert lex("11 - 22") == ["11", "-", "22"]
    assert lex("11 -22") == ["11", "-22"]
    assert lex("11-22") == ["11", "-", "22"]
    assert lex("11 -22 33") == ["11", "-22", "33"]
    assert lex("1.1 2.2 3.3") == ["1.1", "2.2", "3.3"]
  end

  test "strings" do
    assert lex(~s/"bob"/) == ["\"bob\""]
    assert lex(~s/"bob man"/) == ["\"bob man\""]
  end

  test "names" do
    assert lex(~s/`bob/) == ["`bob"]
    assert lex(~s/`"bob man"/) == ["`\"bob man\""]
  end

  test "vars" do
    assert lex(~s/name/) == ["name"]
  end

  test "monadic verbs" do
    assert lex("!2") == ["!", "2"]
    assert lex("@2") == ["@", "2"]
    assert lex("_2") == ["_", "2"]
    assert lex("%2") == ["%", "2"]
    assert lex("^2 3") == ["^", "2", "3"]
    assert lex("?2 3") == ["?", "2", "3"]
    assert lex("~2") == ["~", "2"]
    assert lex("=1 2 2 2 3") == ["=", "1", "2", "2", "2", "3"]
  end

  test "dyadic verbs" do
    assert lex("12 + 34") == ["12", "+", "34"]
    assert lex("1-1") == ["1", "-", "1"]
    assert lex("1>2") == ["1", ">", "2"]
    assert lex("1<2") == ["1", "<", "2"]
    assert lex("1&2") == ["1", "&", "2"]
    assert lex("1|2") == ["1", "|", "2"]
    assert lex("1#1 2 3") == ["1", "#", "1", "2", "3"]
  end

  test "combining verbs" do
    assert lex("*|2 3 1") == ["*", "|", "2", "3", "1"]
    assert lex("1+!2") == ["1", "+", "!", "2"]
  end
  test "comments" do
    assert lex("/nice haircut") == []
    assert lex("a+1 /increase a by 1") == ["a", "+", "1"]
  end

  test "multiple expressions" do
    assert lex("no:2;no") == ["no", ":", "2", ";", "no"]
    assert lex("no:2;na:6;no*na") == ["no", ":", "2", ";", "na", ":", "6", ";", "no", "*", "na"]
  end
end
