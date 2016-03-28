alias StockfighterAPI.{Order, OrderStatus}

defmodule OrderWorker do
  use GenServer

  defstruct retries: 5,
            recordPID: nil,
            oStatus: %OrderStatus{}


  def start_link(%Order{} = order, recordPID) do
    GenServer.start_link(__MODULE__, {order, recordPID} , [])
  end

  # def putOrder(pid, order) do
  #   GenServer.cast(pid, {:put, order})
  # end

  def kill(pid) do
    # GenServer.call(pid, :killOrder)
    GenServer.stop(pid)
  end

  def getStatus(pid) do
    GenServer.call(pid, :getStatus)
  end

  # OrderWorker (callbacks)
  def init({order, recordPID}) do
    oStatus = Order.place(order)
    Process.send_after(self, :update, 1000)
    {:ok, %OrderWorker{oStatus: oStatus, recordPID: recordPID}}
  end

  def handle_call(:getStatus, _from, %OrderWorker{} = st) do
    {:reply, st.oStatus, st}
  end

  def handle_call(:killOrder, _from, %OrderWorker{} = st) do
    new_oStatus = OrderStatus.cancel(st.oStatus)
    OrderRecord.reportStatus(st.recordPID, new_oStatus)
    {:stop, :normal, %{st | oStatus: new_oStatus}}
  end

  def handle_info(:update, %OrderWorker{retries: 0} = st) do
    new_oStatus = OrderStatus.cancel(st.oStatus)
    OrderRecord.reportStatus(st.recordPID, new_oStatus)
    {:stop, :normal, %{st | oStatus: new_oStatus}}
  end

  def handle_info(:update, %OrderWorker{} = st) do
    new_oStatus = OrderStatus.get(st.oStatus)
    if OrderStatus.filled?(new_oStatus) do
      OrderRecord.reportStatus(st.recordPID, new_oStatus)
      {:stop, :normal, %{st | oStatus: new_oStatus}}
    else
      Process.send_after(self, :update, 1000)
      {:noreply, %{st | retries: (st.retries-1), oStatus: new_oStatus}}
    end
  end

  def castStatus(recordPID, %OrderStatus{} = oStatus) do
    GenServer.cast(recordPID, oStatus)
  end
end