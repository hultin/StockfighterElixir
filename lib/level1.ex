alias StockfighterAPI.{Order, StockQuote, Orderbook, OrderStatus}

defmodule Job do
  defstruct account: "EXB123456",
            venue: "TESTEX",
            symbol: "FOOBAR",
            maxPrice: 0,
            maxSize: 100,
            goal: 100000,
            inv: 0

  def newOrder(job) do
    %Order{ account: job.account,
            venue: job.venue,
            symbol: job.symbol,
            price: job.maxPrice,
            orderType: "limit"}
  end

  def nextSize(job) do
    togo = job.goal - job.inv
    cond do
      togo <= 0 -> {:done, :jobFilled}
      true      -> {:ok, min(togo, job.maxSize)}
    end
    
  end

  def goodPrice(job) do
    case StockQuote.get(job.venue, job.symbol) do
      %{askDepth: 0} -> {:error, :noSellers}
      %{ask: ask} ->  cond do
                        ask > round(job.maxPrice)  -> {:error, {:toExpensive, ask}}
                        true                -> {:ok, ask}
                      end
    end
  end

  def step(job) do
    order =
      with  {:ok, qty} <- nextSize(job),
            {:ok, price} <- goodPrice(job),
            do: {:ok, Map.merge(newOrder(job), %{qty: qty, price: price})}

    case order do
      {:ok, o} -> placeOrder(job, o)
      {:error, _} = err -> err
      {:done, _} = done -> done
    end
  end

  defp placeOrder(job, order) do
    %{qty: qty, price: price} = order
    IO.puts "Order #{qty} @ #{price}"
    %{id: orderID} = Order.place order
    checkOrder(job, orderID, 40)
  end

  defp checkOrder(job, orderID, 0) do
    %{totalFilled: tf} = OrderStatus.get(job.venue, job.symbol, orderID)
    newJob = %{job | inv: (job.inv + tf)}
  end

  defp checkOrder(job, orderID, tries) do
    %{totalFilled: tf, price: price, open: isOpen} = OrderStatus.get(job.venue, job.symbol, orderID)
    IO.puts "oID #{orderID} Filled #{tf} @ #{price}"
    case isOpen do
      true -> checkOrder(job, orderID, tries-1)
      false -> newJob = %{job | inv: (job.inv + tf)}
    end
    
  end

  def run(job, 0) do
    {:error, {:retrysTimeOut, job}}
  end

  def run(job, retrys) do
    IO.inspect job
    case step(job) do
      {:done, _} -> :done
      {:error, :noSellers} -> 
          IO.puts "No seller, 2 sec sleep"
          :timer.sleep(2000); 
          run(job, (retrys-1))

      {:error, {:toExpensive, bp}} -> 
          IO.puts "No good price, best price #{bp}, 1 sec sleep"
          :timer.sleep(1000); 
          run(job, (retrys-1))

      %Job{} = newJob -> run(newJob, retrys)
    end
  end
end

defmodule PrepTest do

  def creatSells  do
    o = %Order{
      account: "EXB123456",
      venue: "TESTEX",
      symbol: "FOOBAR",
      direction: "Sell", 
      price: randInRange(1000, 6000), 
      orderType: "limit", 
      qty: randInRange(2, 500)}
    Order.place o
  end

  def creatBuys  do
    o = %Order{
      account: "EXB123456",
      venue: "TESTEX",
      symbol: "FOOBAR",
      direction: "Buy", 
      price: randInRange(1000, 6000), 
      orderType: "limit", 
      qty: randInRange(2, 500)}
    Order.place o
  end

  def randInRange(min, max) do
    :random.seed(:erlang.timestamp)
    r = :random.uniform(1 + max - min)
    r + min - 1
  end
end

defmodule Level1 do
  def start do
    # j = %Job{account: "RMS68876395", goal: 100000, inv: 100, maxPrice: 3945, maxSize: 300, symbol: "IAEJ", venue: "WULOEX"}   
    j = %Job{account: "HB4225042", symbol: "SKC", venue: "PUIZEX", goal: 100000, inv: 100, maxPrice: 4340, maxSize: 500}   
    Job.run(j, 400)
  end
end