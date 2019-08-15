defmodule Ke.Help do
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
  def help, do: @help_text

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

  ke is parsed right-to-left. There is no other order of precedence. This can
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
  def intro, do: @intro_text
end
