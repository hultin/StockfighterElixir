
alias StockfighterAPI.{Order, OrderStatus}
# alias StockfighterAPI.{Order, StockQuote, Orderbook, OrderStatus}

defmodule OrderRecord do
  use GenServer

  defstruct workerSup: nil 

  def tOrder ,do: %StockfighterAPI.Order{account: "EXB123456", direction: "Sell", orderType: "limit", price: 1151, qty: 273, symbol: "FOOBAR", venue: "TESTEX"}

  def start_link(name, supPID) do
    GenServer.start_link(__MODULE__, {:ok, supPID}, name: name)
  end
  
  def newOrder(orderRec, %Order{} = order) do
    GenServer.call(orderRec, {:newOrder, order})
  end

  def reportStatus(orderRec, %OrderStatus{} = oStatus) do
    GenServer.cast(orderRec, {:orderStatus, oStatus})
  end

  def handle_call({:newOrder, order}, _from, state) do
    {:ok, pid} = Supervisor.start_child(state.workerSup, [order, self])
    oStatus = OrderWorker.getStatus(pid)
    {:reply, oStatus, state}
  end

  def handle_cast({:orderStatus, oStatus}, state) do
    IO.puts "Reported status:"
    IO.inspect oStatus
    {:noreply, state}
  end

  def init({:ok, supPID}) do
    Process.send(self, {:startOrdersWorkerSup, supPID}, [])
    {:ok, 1}
  end


  def handle_info({:startOrdersWorkerSup, supPID}, state) do
    workerSup = Supervisor.Spec.supervisor(OrderWorker.Supervisor, [])
    {:ok, workerSupPID} = Supervisor.start_child(supPID, workerSup)
    {:noreply, %OrderRecord{workerSup: workerSupPID}}
  end
end