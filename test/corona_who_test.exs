defmodule CoronaWhoTest do
  use ExUnit.Case
  doctest CoronaWho

  test "greets the world" do
    assert CoronaWho.hello() == :world
  end
end
