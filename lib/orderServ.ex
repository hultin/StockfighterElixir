
defmodule OrderServ do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  def putOrder(pid, order) do
    GenServer.cast(pid, {:put, order})
  end

  def getOrder(pid) do
    GenServer.call(pid, :get)
  end

  # OrderServ (callbacks)
  def handle_cast({:put, order}, state) do
    IO.inspect state
    {:noreply, [order|state]}
  end

  def handle_call(:get, _from, [h|t]) do
    {:reply, h, t}
  end

end