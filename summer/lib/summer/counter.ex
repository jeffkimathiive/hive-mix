defmodule Summer.Counter do
  def new(input) do
    String.to_integer(input)
  end

  def add(acc, num) do
    acc + num
  end

  def show(acc) do
    "Acc eh? #{acc}"
  end
end
