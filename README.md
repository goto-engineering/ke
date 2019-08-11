# ke

[k](https://en.wikipedia.org/wiki/K_(programming_language)) in Elixir

*Warning: super alpha status*

Inspired by k7

[kparc](http://kparc.com) k website

[+/∞](https://kcc.kparc.io) Learn k

[+/kei](https://ref.kparc.io/) K reference

## Examples

From `test.ke`:
```
  /Addition
  1+1
2

  /atomic operators like + work on lists
  1 1 1 + 2 2 2
3 3 3

  /numbers up til 10 (excluding)
  !10
0 1 2 3 4 5 6 7 8 9

  /add 1 to get 1-10
  1+!10
1 2 3 4 5 6 7 8 9 10

  /subtraction
  1 - 2
-1

  /division
  3 % 4
0.75

  /reciprocal
  %5
0.2

  /enlist a scalar
  ,10 / The preceding , means this is a list of a single item
,10

  /concat lists
  10 10,30 30
10 10 30 30

  /just a string
  "bob"
"bob"

  /first item from list
  *1 2 3
1

  /reverse list
  |1 2 3
3 2 1

  /last item from list - reverse, then take first
  *|1 2 3
3

  /negative number
  -99
-99

  /grouping list of integers
  =1 2 3 4 4 1
1|0 5
2|,1
3|,2
4|3 4

  /grouping a string
  ="Bobby"
B|,0
b|2 3
o|,1
y|,4

  /multiplying 10 times the numbers from 0-5 + 1
  10*1+!5
10 20 30 40 50
  
  /exclude
  "Bobby"^"oy"
"Bbb"

  /assign 1 to variable a
  a:1

  /get it back
  a
1

  /use variable with verb
  a*2
2

	/count
  #"buffalo"
7

	/equality is atomic too
  1 1 1=1 1 2
1 1 0

  /negate
  ~0
1

  ~1
0

  /negate is atomic on strings
  /and apparently all letters are truthy
  ~"bob"
0 0 0

  /index
  "bob"@1
"o"

  /equality in strings
  "Bob"="Bob"
1

  "Bob"="bob"
0

  /type is integer
  @1
`i

  /type of list is integer if it is made of integers
  @1 2 3
`i

  /type of string is character
  @"Bob"
`c
```

## Install

### Install Elixir:

Mac:
`brew install elixir`

Ubuntu:
`apt install elixir`. Consider adding the erlang-solutions apt repository for a more up-to-date version of Elixir. Tested with Elixir 1.9, but probably works with older versions as well.

Windows and other Linuxes/Unixes:
`God helps those who help themselves`

### Clone this repo

`git clone https://github.com/goto-engineering/ke.git`

### Build ke escript

Escript lets you build and install an executable.

Create a `ke` binary in the project folder:
`mix escript.build`

Install to `~/.mix/escripts`:
`mix escript.install`

## Start the REPL

If you've built the escript:
`./ke`

You can also directly run the `mix` task instead:
`mix repl`

Cancel by pressing typing `\\` followed by enter. You can also Ctrl-c twice, like any Erlang application.

## Run files

`./ke test.ke`

## Run unit tests

`mix test`

## TODO

1. Order of presedence `()`
1. Nested arrays `(1 1;2 2)`
1. Functions `{x+y}`
1. nil vs nothing vs that zero k has?
1. Statement separator `;`
1. Example list generated from `test.ke`
1. Parse negative numbers with higher presedence
1. \# takes array as first operand, takes multi-dimensionally
1. How to `rlwrap` the escript binary?
1. Print array inline if it is all numbers, not all ints/all floats
1. Don't crash the REPL on errors
1. Make file runner maintain env
1. Dedicated example page to keep README clean?

The following is still missing:
```
Verb                       Adverb                Noun              Type
                           '  each      n bar
+              flip        /  over      n div          ``a
                           \  scan      n mod
                           ': eachprior peach          ø     π ∞
                           /: eachright sv|join  date 2019-06-28   `D .z.D
&              where       \: eachleft  vs|split time 12:34:56.789 `t .z.t
                      
<              up          I/O (0:h close)
>              down        0: read/write line    dict {a:2;b:`c}   `a
                           1: read/write byte    tabl +{a:2 3 4}   `A
~  match                   2: read/write data    expr :32+9*f%5    `0
!  key                     3: conn/set (.Z.[gs]) func {(+/x)%#x}   `1
                           4: http/get (.Z.[GS])

                           #[t;c;b[;a]] select   \l f.k  load
                           _[t;c;b[;a]] update   \t[:n]x milli/time \l log
                            [x;i;f[;y]] splice   \u[:n]x micro/trace
                           @[x;i;f[;y]] amend    \v [d] vars        \f [d] fns
.  apply       value       .[x;i;f[;y]] dmend    \lf file \lc char  \ll line
$  cast|pad    string      $[c;t;f]     cond     \cd [d] get[set]   \gr x file
```
