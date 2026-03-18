defmodule Increaser.Worker do
use GenServer
  alias Increaser.Counter

  @impl true
  def init(init_arg) do
    {:ok, Counter.new(init_arg)}
  end

  def start_link(input) do
    GenServer.start_link(__MODULE__, input, name: __MODULE__)
  end

  def show() do
    GenServer.call(__MODULE__, :show)
  end

  def inc() do
    GenServer.cast(__MODULE__, :inc)
  end

  @impl true
  def handle_call(:show, _from, state) do
    result = Counter.show(state)
    {:reply, result, state}
  end

  @impl true
  def handle_cast(:inc, state) do
    result = Counter.add(state, 1)
    {:noreply, result}
  end
end
