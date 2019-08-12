defmodule Ke.CLI do
  def main(opts) do
    case opts do
      [] -> Ke.repl()
      [file] when is_binary(file) -> Ke.run_file(file)
      _ -> IO.puts """
        Usage:
        ke.exs            Starts REPL
        ke.exs <file.ke>  Run code in file.ke
        ke.exs --tests    Runs unit tests
        """
    end
  end
end
