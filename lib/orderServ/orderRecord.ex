
alias StockfighterAPI.{Order, OrderStatus}
# alias StockfighterAPI.{Order, StockQuote, Orderbook, OrderStatus}

defmodule OrderRecord do
  use GenServer

  defstruct workerSup: nil,
            openOrders: 0,
            closedOrders: 0,
            totalFilled: 0

  def tOrder ,do: %StockfighterAPI.Order{account: "EXB123456", direction: "Buy", orderType: "limit", price: 9400, qty: 273, symbol: "FOOBAR", venue: "TESTEX"}

  def start_link(name, supPID) do
    GenServer.start_link(__MODULE__, {:ok, supPID}, name: name)
  end
  
  def newOrder(orderRec, %Order{} = order) do
    GenServer.call(orderRec, {:newOrder, order})
  end

  def getState(orderRec) do
    GenServer.call(orderRec, :getState)
  end

  def reportStatus(orderRec, %OrderStatus{} = oStatus) do
    GenServer.cast(orderRec, {:orderStatus, oStatus})
  end

  def handle_call(:getState, _from, st), do: {:reply, st, st}

  def handle_call({:newOrder, order}, _from, st) do
    {:ok, pid} = Supervisor.start_child(st.workerSup, [order, self])
    # oStatus = OrderWorker.getStatus(pid)
    oo = st.openOrders + 1
    {:reply, {:ok, pid}, %{st | openOrders: oo}}
  end

  def handle_cast({:orderStatus, oStatus}, st) do
    IO.puts "Reported status:"
    tf = st.totalFilled + oStatus.totalFilled
    {:noreply, %{st | totalFilled: tf}}
  end

  def init({:ok, supPID}) do
    Process.send(self, {:startOrdersWorkerSup, supPID}, [])
    {:ok, %OrderRecord{}}
  end

  def handle_info({:startOrdersWorkerSup, supPID}, st) do
    workerSup = Supervisor.Spec.supervisor(OrderWorker.Supervisor, [])
    {:ok, workerSupPID} = Supervisor.start_child(supPID, workerSup)
    {:noreply, %{st | workerSup: workerSupPID}}
  end
end