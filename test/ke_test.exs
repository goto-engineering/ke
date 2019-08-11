defmodule KeTest do
  import Ke
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Ke

  test "scalars" do
    assert interpret("") == nil
    assert interpret("1") == "1"
    assert interpret("42") == "42"
    assert interpret("1.5") == "1.5"
    assert interpret("`name") == "`name"
  end

  test "strings" do
    assert interpret(~s/"name is good"/) == ~s/"name is good"/
  end

  test "arrays" do
    assert interpret("1 2") == "1 2"
    assert interpret("1 2 3") == "1 2 3"
    assert interpret("10 20") == "10 20"
    assert interpret("1.1 2.4 3.5") == "1.1 2.4 3.5"
    assert interpret("1 2.3 4") == "1 2.3 4"

    exp = String.trim("""
    1
    "bob man"
    `two
    """)
    assert interpret(~s/1 "bob man" `two/) == exp

    exp = String.trim("""
    1
    "bob man"
    `two
    """)
    assert interpret(~s/(1;"bob man";`two)/) == exp

    assert interpret(~s/(1 1 2 2 3 3)/) == "1 1 2 2 3 3"
  end

  test "addition" do
    assert interpret("1+1") == "2"
    assert interpret("22 + 22") == "44"
    assert interpret("1 2 3 + 1") == "2 3 4"
    assert interpret("1 2 3+1") == "2 3 4"
    assert interpret("1 + 1 2 3") == "2 3 4"
    assert interpret("1 1 1 + 2 2 2") == "3 3 3"
  end

  test "subtraction" do
    assert interpret("42 - 23") == "19"
    assert interpret("2 2 2 - 1") == "1 1 1"
    assert interpret("2 - 1 1 1") == "1 1 1"
  end

  test "negate" do
    assert interpret("-1") == "-1"
    assert interpret("-10 20") == "-10 -20"
  end

  test "multiplication" do
    assert interpret("1 1 1 * 3") == "3 3 3"
    assert interpret("1.5*2 2 2") == "3.0 3.0 3.0"
  end

  test "division" do
    assert interpret("4 4 4 % 2") == "2.0 2.0 2.0"
    assert interpret("4 % 2 2 2") == "2.0 2.0 2.0"
    assert interpret("2.2 2.4 2.5%4") == "0.55 0.6 0.625"
  end

  test "reciprocal" do
    assert interpret("%5") == "0.2"
    assert interpret("%1 2 3") == "1.0 0.5 0.3333333"
  end

  test "til" do
    assert interpret("!10") == "0 1 2 3 4 5 6 7 8 9"
  end

  test "enlist" do
    assert interpret(",1") == ",1"
  end

  test "join" do
    assert interpret("1, 2") == "1 2"
    assert interpret("1 1, 2") == "1 1 2"
    assert interpret("1, 2 2") == "1 2 2"
    assert interpret("1 1, 2 2") == "1 1 2 2"
    assert interpret(~s/"Bob","by"/) == ~s/"Bobby"/
  end

  test "array length matches" do
    assert interpret("1 2 3 + 1 1 1 1") == "Error: Array length doesn't match: 3, 4"
  end

  test "comments" do
    assert interpret("/this is a comment") == nil
    assert interpret("1 + 1 /this is a comment") == "2"
  end

  test "min" do
    assert interpret("2&3") == "2"
    assert interpret("3&2") == "2"
  end

  test "count" do
    assert interpret("#1") == "1"
    assert interpret("#1 3") == "2"
    assert interpret("#1 2 3") == "3"
    assert interpret("#1 2 3 4") == "4"
    assert interpret(~s/#"Bob"/) == "3"
  end

  test "less" do
    assert interpret("2<3") == "1"
    assert interpret("3<2") == "0"
    assert interpret("1 2<5 3") == "1 1"
    assert interpret("1 3<5 2") == "1 0"
    assert interpret("4.2 < 59.2") == "1"
  end

  test "greater" do
    assert interpret("2>3") == "0"
    assert interpret("3>2") == "1"
    assert interpret("1 2>5 3") == "0 0"
    assert interpret("1 3>5 2") == "0 1"
  end

  test "equals" do
    assert interpret("2=2") == "1"
    assert interpret("3=2") == "0"
    assert interpret("1 1=1 1") == "1 1"
    assert interpret("1 3=1 2") == "1 0"
  end

  test "max" do
    assert interpret("2|3") == "3"
    assert interpret("3|2") == "3"
  end

  test "reverse" do
    assert interpret("|1") == "1"
    assert interpret("|1 3") == "3 1"
    assert interpret("|1 2 3") == "3 2 1"
    assert interpret("|1 2 3 4") == "4 3 2 1"
  end

  test "first" do
    assert interpret("*1 2 3") == "1"
    assert interpret("*|1 2 3 4") == "4"
    assert interpret(~s/*|"NYC"/) == ~s/"C"/
  end

  test "not" do
    assert interpret("~1") == "0"
    assert interpret("~0") == "1"
    assert interpret("~1 0 3 4") == "0 1 0 0"
    assert interpret(~s/~"Bob"/) == "0 0 0" # when are characters ever not truthy? ascii 0?
  end

  test "type" do
    assert interpret(~s/@"B"/) == "`c"
    assert interpret(~s/@"Bob"/) == "`c"
    assert interpret("@2") == "`i"
    assert interpret("@1 2") == "`i"
    assert interpret("@1.5") == "`f"
    assert interpret("@`name") == "`n"
    assert interpret_env("@thing", %{"thing" => :name}) == {"`n", %{"thing" => :name}}
    assert interpret("@2.5 3.5") == "`f"
    assert interpret("@(1;`tree)") == "`."
    assert interpret(~s/@("bob hello";"man")/) == "`c"
    assert interpret(~s/`"bob man"/) == ~s/`"bob man"/
  end

  test "index" do
    assert interpret("1 2 3@0") == "1"
    assert interpret("1 2 3@1") == "2"
    assert interpret("1 2 3@2") == "3"
    assert interpret("1 2 3@5") == "Ø"
    assert interpret(~s/"Bob"@1/) == ~s/"o"/
    assert interpret(~s/"Bob"@5/) == ~s/" "/
  end

  test "except" do
    assert interpret("1 2 3^2") == "1 3"
    assert interpret("1 2 3^1 2") == ",3"
    assert interpret(~s/"Bob"^"o"/) == ~s/"Bb"/
    assert interpret(~s/"Bobby"^"oy"/) == ~s/"Bbb"/
  end

  test "group" do
    assert interpret("=1 2 3 3") == """
    1|,0
    2|,1
    3|2 3
    """
    assert interpret(~s/="Bobby"/) == """
    B|,0
    b|2 3
    o|,1
    y|,4
    """
  end

  test "combine verbs" do
    assert interpret("1+!5") == "1 2 3 4 5"
    assert interpret("1+5-59*!3") == "6 -53 -112"
    assert interpret("%-2") == "-0.5"
  end

  test "assign" do
    assert interpret_env(~s/name:"Bob"/) == {nil, %{"name" => "Bob"}}
    assert interpret_env("n:1+1") == {nil, %{"n" => 2}}
    assert interpret_env("b:!5") == {nil, %{"b" => [0, 1, 2, 3, 4]}}
    assert interpret_env("a", %{"a" => 42}) == {"42", %{"a" => 42}}
    assert interpret_env("@a", %{"a" => 42}) == {"`i", %{"a" => 42}}
    assert interpret_env("@name", %{"name" => "Bob"}) == {"`c", %{"name" => "Bob"}}
    assert interpret_env("a+1", %{"a" => 42}) == {"43", %{"a" => 42}}
    assert interpret_env("1+a", %{"a" => 42}) == {"43", %{"a" => 42}}
    assert interpret_env("unknown", %{}) == {"Error: Variable `unknown` is undefined", %{}}
    assert interpret_env("a+1", %{}) == {"Error: Variable `a` is undefined", %{}}
    assert interpret_env("1+a", %{}) == {"Error: Variable `a` is undefined", %{}}
    assert interpret_env("a+b", %{}) == {"Error: Variable `a` is undefined", %{}}
    assert interpret_env("!n", %{}) == {"Error: Variable `n` is undefined", %{}}
    assert interpret_env("~a b c", %{}) == {"""
    Error: Variable `a` is undefined
    Error: Variable `b` is undefined
    Error: Variable `c` is undefined
    """ |> String.trim, %{}}
    assert interpret_env("bad", %{data: "42"}) == {"Error: Variable `bad` is undefined", %{data: "42"}}
  end

  test "commands" do
    assert interpret("\\\\") == {:cmd, :exit}
  end

  test "floor" do
    assert interpret("_1.5") == "1"
    assert interpret("_1.5 2.5 3.5") == "1 2 3"
  end

  test "unique" do
    assert interpret("?1 1 1 2") == "1 2"
    assert interpret(~s/?"Mississippi"/) == ~s/"Misp"/
  end

  test "drop" do
    assert interpret("1_1 2 3") == "2 3"
    assert interpret(~s/1_"bob"/) == ~s/"ob"/
    assert interpret("10_1 2 3") == ""
    assert interpret(~s/4_"bob"/) == ~s/""/
  end

  test "find" do
    assert interpret("1 2 3?1") == "0"
    assert interpret("1 2 3?2") == "1"
    assert interpret("1 2 3?3") == "2"
    assert interpret("1 2 3?4") == "3"
    assert interpret(~s/"bobby"?"b"/) == "0"
    assert interpret(~s/"bobby"?"y"/) == "4"
    assert interpret(~s/"bobby"?"z"/) == "5"
  end

  test "take" do
    assert interpret("1#1 2 3 4") == ",1"
    assert interpret("2#1 2 3 4") == "1 2"
    assert interpret(~s/1#"bob"/) == ~s/"b"/
    assert interpret(~s/2#"bob"/) == ~s/"bo"/
    assert interpret("9#1 2 3 4") == "1 2 3 4 1 2 3 4 1"
    assert interpret(~s/7#"bob"/) == ~s/"bobbobb"/
  end

  test "sort asc" do
    assert interpret("^3 2.5 1 4") == "1 2.5 3 4"
    assert interpret(~s/^"Mississippi"/) == ~s/"Miiiippssss"/
  end

  test "up" do
    assert interpret("<3 1 83 94") == "1 0 2 3"
    assert interpret(~s/<"Bob"/) == "0 2 1"
  end

  test "down" do
    assert interpret(">3 1 83 94") == "3 2 0 1"
    assert interpret(~s/>"Bob"/) == "1 2 0"
  end

  test "running files" do
    assert capture_io(fn -> Ke.run_file("examples/test.ke") end) == """
    "Bob"
    "Hi, Bob!"
    """
  end

  test "TODO" do
    # evaling undefined var in array doesn't error

    # Wait, there is such a thing as right-atomic? Or is this just a special case?
    # assert interpret(~s/"abcdefgh"?"ac"/) == "0 2"
    # assert interpret(~s/1 2 3 4 5?1 5/) == "0 4"
    # assert interpret_env(~s/^s=s@<s/, %{"s" => "Mississippi"}) == "true?"

    # Parse negative numbers before right-to-left
    # assert interpret("-1_1 2 3") == "1 2"
    # assert interpret(~s/-1_""/) == ~s/"bo"/
    # assert interpret("-1#1 2 3 4") == ",4"
    # assert interpret(~s/-1#"bobby"/) == ~s/"y"/

    # Semicolon, is this a parser issue?
    # assert interpret_env("a:2;a") == {"2", %{a: 2}}
  end
end
