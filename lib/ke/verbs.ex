defmodule Ke.Verbs do
  import Ke.Debug
  def mo(:","), do: &enlist/1
  def mo(:!), do: &(0..(&1-1) |> Enum.to_list())
  def mo(:-), do: &(-&1)
  def mo(:*), do: fn
    l when is_list(l) -> Enum.at(l, 0)
    s when is_binary(s) -> String.first(s)
  end
  def mo(:%), do: &(1 / &1)
  def mo(:"#"), do: fn
    l when is_list(l) -> length(l)
    s when is_binary(s) -> String.length(s)
    _ -> 1
  end
  def mo(:|), do: fn 
    l when is_list(l) -> Enum.reverse(l)
    s when is_binary(s) -> String.reverse(s)
    x -> x
  end
  def mo(:"~"), do: fn
    l when is_list(l) -> Enum.map(l, &(unbool(&1 == 0)))
    s when is_binary(s) ->
    String.split(s, "", trim: true)
    |> Enum.map(&(unbool(&1 == 0)))
    x -> unbool(x == 0)
  end
  def mo(:@), do: fn
    i when is_integer(i) -> :i
    f when is_float(f) -> :f
    s when is_binary(s) -> :c
    a when is_atom(a) -> :n
    l when is_list(l) -> cond do
      Enum.all?(l, &is_integer/1) -> :i
      Enum.all?(l, &is_float/1) -> :f
      Enum.all?(l, &is_binary/1) -> :c
      true -> :.
    end
    _ -> :type_missing
  end
  def mo(:=), do: fn
    s when is_binary(s) -> String.split(s, "", trim: true) |> group()
    l when is_list(l) -> group(l)
  end
  def mo(:_), do: &floor/1
  def mo(:"?"), do: fn
    s when is_binary(s) -> s |> String.split("", trim: true) |> Enum.uniq |> Enum.join
    l when is_list(l) -> Enum.uniq(l)
  end
  def mo(:^), do: fn
    s when is_binary(s) -> s |> String.split("", trim: true) |> Enum.sort |> Enum.join("")
    l when is_list(l) -> Enum.sort(l)
  end
  def mo(:<), do: fn
    l when is_list(l) -> up(l)
    s when is_binary(s) -> String.split(s, "", trim: true) |> up
  end
  def mo(:>), do: fn
    l when is_list(l) -> down(l)
    s when is_binary(s) -> String.split(s, "", trim: true) |> down
  end
  def mo(:&), do: fn l ->
    Enum.with_index(l)
    |> Enum.map(fn {n, i} -> String.duplicate(Integer.to_string(i), n)
    |> String.split("", trim: true) end)
    |> List.flatten
    |> Enum.map(&String.to_integer/1)
  end
  def mo(:+), do: fn 
    l when is_list(l) ->
    deb(l)
    if Enum.all?(l, &(is_list(&1))) do
      Enum.zip(l)
      |> deb
      |> Enum.map(&Tuple.to_list/1)
      |> deb
    else
      l
    end
    s when is_binary(s) -> s
  end
  def mo(token), do: raise "Missing monadic #{token}"

  def dy(:+), do: &+/2
  def dy(:-), do: &-/2
  def dy(:*), do: &*/2
  def dy(:%), do: &//2
  def dy(:&), do: &min/2
  def dy(:|), do: &max/2
  def dy(:","), do: fn
    (s1, s2) when is_binary(s1) and is_binary(s2) -> Enum.join([s1, s2])
    (l1, l2) -> enlist([l1, l2])
  end
  def dy(:<), do: &(unbool(&1 < &2))
  def dy(:>), do: &(unbool(&1 > &2))
  def dy(:=), do: &(unbool(&1 == &2))
  def dy(:@), do: fn
    (s, i) when is_binary(s) -> String.at(s, i) || " "
    (array, i) -> Enum.at(array, i) || :null
  end
  def dy(:^), do: fn
    (s, exclude_chars) when is_binary(s) and is_binary(exclude_chars) ->
      String.replace(s, exclude_chars |> String.split("", trim: true), "")
    (array, exclude) -> Enum.reject(array, &(Enum.member?(enlist(exclude), &1)))
  end
  def dy(:_), do: fn
    (c, s) when is_binary(s) and is_integer(c) and c > 0 -> String.slice(s, c, String.length(s))
    (c, s) when is_binary(s) and is_integer(c) -> String.slice(s, 0, String.length(s) - c)
    (c, l) when is_list(l) and is_integer(c) and c > 0 -> Enum.slice(l, c, length(l))
    (c, l) when is_list(l) and is_integer(c) -> Enum.slice(l, 0, length(l) - c)
  end
  def dy(:"?"), do: fn
    (s, v) when is_binary(s) -> s |> String.split("", trim: true) |> find(v)
    (l, v) when is_list(l) -> find(l, v)
  end
  def dy(:"#"), do: fn (c, l) -> take_repeatedly(l, c) end
  def dy(token), do: raise "Missing dyadic #{token}"

  defp enlist(x), do: [x] |> List.flatten
  defp unbool(expr), do: if expr, do: 1, else: 0
  defp group(array) do
    indexed_list = Enum.with_index(array)
    array
    |> Enum.uniq
    |> Enum.reduce(%{}, fn (x, acc) ->
      indices = Enum.filter(indexed_list, fn {v, _} -> v == x end)
                |> Enum.map(&(elem(&1, 1)))
      Map.put(acc, x, indices) 
    end)
  end
  defp find(l, v), do: l |> Enum.find_index(&(&1 == v)) || length(l)
  defp take_repeatedly(l, c) when is_list(l) do
    count = div(c, length(l))
    whole_parts = List.duplicate(l, count) |> List.flatten
    whole_parts ++ Enum.slice(l, 0, rem(c, length(l)))
  end
  defp take_repeatedly(s, c) when is_binary(s) do
    String.duplicate(s, div(c, String.length(s))) <> String.slice(s, 0, rem(c, String.length(s)))
  end
  defp up(l) do
    Enum.with_index(l)
    |> Enum.sort(fn ({n1, _}, {n2, _}) -> n1 <= n2 end)
    |> Enum.map(fn {_, i} -> i end)
  end
  defp down(l) do
    Enum.with_index(l)
    |> Enum.sort(fn ({n1, _}, {n2, _}) -> n1 >= n2 end)
    |> Enum.map(fn {_, i} -> i end)
  end
end
