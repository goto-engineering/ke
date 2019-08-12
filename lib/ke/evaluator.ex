defmodule Ke.Evaluator do
  alias Ke.Verbs, as: Verbs

  @intro_text """
  Verbs form the basic operations.

  Dyadic means the verb has 2 operands:
    2+2
  4

  Monadic means the verb only has an operand on the right:
    !5
  0 1 2 3 4

  Certain verbs are atomic, i.e. they will operate on each item of an array
  individually when used on an array:
    2*1 1 1
  2 2 2

  Other verbs are not atomic and operate on the whole array instead:
    1 2 3,4 5 6
  1 2 3 4 5 6

  ke is parsed right-to-left. There is no other order of presedence. This can
  lead to confusion with math:
    10*1-2
  -10

  The equivalent S-expression makes this more obvious:
  (* 10 (- 1 2))

  ke is parsed like Lisp, although it looks different. Right-to-left is inside-out.

  You can enter arrays of only numbers with just spaces in between:
    1 2 3 4.5 6
  1 2 3 4.5 6

  To enter lists of mixed types, or to be more explicit:
    (1;2)
  1 2

    (1;`trees;"bill";4.5)
  1
  `trees
  "bill"
  4.5

  Mixed lists are displayed with each entry on a separate line.
  """

  @help_text """
  Incomplete implementation inspired by k7.
  Type \\intro for an introduction.

  Verb                                             Noun              Type
     (dyadic)    (monadic)                         
  :  assign                                        char  " ab"       `c
  +  add         flip                              name     `b       `n
  -  subtract    negate                            int     0 2       `i
  *  multiply    first                             float   2.3       `f
  %  divideby    inverse
  &  min|and     where
  |  max|or      reverse
                                                   list (2;3.4;`c)   `.
  <  less        up
  >  more        down
  =  equal       group
  ~              not
  !              enum
  ,  catenate    enlist
  ^  except      asc
  #  take        count                                               \\h help
  _  drop        floor
  ?  find        unique
  @  index       type
  """

  @atomic_dyad ~W"+ - % ! * | & < > ="a
  @non_atomic_dyad ~W", @ ^ : _ ? #"a

  @atomic_monoid ~W"% - ~ , _"a
  @non_atomic_monoid ~W"* ! , # | @ = ? ^ < > & +"a

  @dyad @atomic_dyad ++ @non_atomic_dyad
  @monoid @atomic_monoid ++ @non_atomic_monoid
  @verb @dyad ++ @monoid

  defp mono(o, {:var, var}, tail, env) do
    case from_env(env, var) do
      {:error, msg} -> {{:error, msg}, env}
      v -> eval(tail, [Verbs.mo(o).(v)], env)
    end
  end
  defp mono(o, v, tail, env), do: eval(tail, [Verbs.mo(o).(v)], env)

  defp mono_map(o, vs, tail, env) do
    values = Enum.map(vs, fn
      {:var, v} -> from_env(env, v)
      v -> v
    end)
    errors = Enum.filter(values, fn
      {:error, _} -> true
      _ -> false
    end)

    if length(errors) > 0 do
      {errors, env}
    else
      eval(tail, [Enum.map(values, &(Verbs.mo(o).(&1)))], env)
    end
  end

  def eval(code) do
    eval(code, %{})
  end

  # Tree node expr
  def eval({:code, expressions}, env) do
    Enum.reduce(expressions, {[], env}, fn (expr, {_, new_env}) ->
      eval(expr, new_env)
    end)
  end

  # List expr
  def eval(expr, env) when is_list(expr) do
    expr
    |> Enum.reverse() # ke is evaluated right to left
    |> eval([], env)
  end
  def eval(expr, env) do
    eval(expr, [], env)
  end

  defp eval({:cmd, "\\\\"}, _, env), do: {{:cmd, :exit}, env}
  defp eval({:cmd, "\\intro"}, _, env), do: {{:intro, @intro_text}, env}
  defp eval({:cmd, "\\h"}, _, env), do: {{:help, @help_text}, env}

  # Do these even eval?! Removed during lexing now?
  # Comments
  defp eval([:/], _, env), do: {nil, env}
  defp eval([:/ | tail], _, env), do: eval(tail, [], env)

  # Monadic verbs
  defp eval([o], [v], env) when o in @atomic_monoid and is_list(v), do: mono_map(o, v, [], env)
  defp eval([o | [next | _ ] = tail], [v], env) when o in @atomic_monoid and is_list(v) and next in @verb, do: mono_map(o, v, tail, env)
  defp eval([o], [v], env) when o in @monoid, do: mono(o, v, [], env)
  defp eval([o | [next | _] = tail], [v], env) when o in @monoid and next in @verb, do: mono(o, v, tail, env)

  # `gets` is the only verb affecting the env
  defp eval([{:var, var}], [:":", value], env), do: eval([], [], Map.put(env, var, value))

  # Dyadic verbs
  defp eval([{:var, var} | tail], [o, b], env) when o in @dyad do
    case from_env(env, var) do
      {:error, msg} -> {{:error, msg}, env}
      v -> eval(tail, [Verbs.dy(o).(v, b)], env)
    end
  end
  defp eval([a | tail], [o, {:var, var}], env) when o in @dyad do
    case from_env(env, var) do
      {:error, msg} -> {{:error, msg}, env}
      v -> eval(tail, [Verbs.dy(o).(a, v)], env)
    end
  end
  defp eval([a | tail], [o, b], env) when o in @atomic_dyad and is_list(a) and not is_list(b) do
    result = a |> Enum.map(fn i -> Verbs.dy(o).(i, b) end)
    eval(tail, [result], env)
  end
  defp eval([a | tail], [o, b], env) when o in @atomic_dyad and not is_list(a) and is_list(b) do
    result = b |> Enum.map(fn i -> Verbs.dy(o).(a, i) end)
    eval(tail, [result], env)
  end
  defp eval([a | tail], [o, b], env) when o in @atomic_dyad and is_list(a) and is_list(b)
  and length(a) == length(b) do
    result = Enum.zip(a, b)
             |> Enum.map(fn {x, y} -> Verbs.dy(o).(x, y) end)
    eval(tail, [result], env)
  end
  defp eval([a | _], [o, b], env) when o in @atomic_dyad and is_list(a) and is_list(b) do
    {{:error, "Array length doesn't match: #{length(a)}, #{length(b)}"}, env}
  end
  defp eval([a | tail], [o, b], env) when o in @dyad do
    eval(tail, [Verbs.dy(o).(a, b)], env)
  end

  # Vars
  defp eval({:var, var}, _, env), do: {from_env(env, var), env}
  defp eval([{:var, var} | tail], acc, env) do
    case from_env(env, var) do
      {:error, msg} -> {{:error, msg}, env}
      v -> eval(tail, [v | acc], env)
    end
  end

  # Lists
  defp eval([], [l], env) when is_list(l) do
    expanded_list = Enum.map(l, fn
      {:var, var} -> from_env(env, var)
      x -> x
    end)
    {expanded_list, env}
  end

  # Scalars
  defp eval([], [], env), do: {nil, env}
  defp eval([], [x], env), do: {x, env}
  defp eval([], x, env), do: {x, env}

  # Continue the expression, a scalar was added to the accumulator
  defp eval([h | tail], acc, env) do
    eval(tail, [h | acc], env)
  end

  defp eval(h, acc, env) do
    eval([], [h | acc], env)
  end

  defp from_env(env, var) do
    case env[var] do
      nil -> {:error, "Variable `#{var}` is undefined"}
      x -> x
    end
  end
end
