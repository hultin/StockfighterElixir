
defmodule OrderRecordSup do
  use Supervisor

  def start_link(name) do
    Supervisor.start_link(__MODULE__, {:ok, name})
  end

  def init({:ok, name}) do
    children = [
      worker(OrderRecord, [name, self()])
    ]

    supervise(children, strategy: :one_for_one)
  end
end