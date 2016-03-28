alias StockfighterAPI.Order

defmodule OrderWorker.Supervisor do
  use Supervisor

  # A simple module attribute that stores the supervisor name
  @name OrderWorker.Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  # def start_order(order = %Order{}) do
  #   Supervisor.start_child(@name, [order])
  # end

  def init(:ok) do
    children = [
      worker(OrderWorker, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
