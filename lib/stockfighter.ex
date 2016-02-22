defmodule StockfighterIO do
  use HTTPotion.Base
  
  def process_url(url) do
    "https://api.stockfighter.io/ob/api/" <> url
  end

  def process_options(options) do
    Dict.put(options, :timeout, 15000)
  end

  def process_response_body(body) do
    body 
    |> IO.iodata_to_binary 
    |> Poison.decode!
    |> key_to_atom
  end

  def process_request_headers(headers) do
    authKey = StockfighterAuthKey.getKey
    headers ++ ["X-Starfighter-Authorization": authKey]
  end

  defp key_to_atom(m) when is_map(m) do
    for {key, val} <- m, into: %{}, do: {String.to_atom(key), key_to_atom(val)}
  end
  defp key_to_atom(m) when is_list(m) do
    for i <- m, do: key_to_atom(i)
  end
  defp key_to_atom(m) do
    m
  end

end

defmodule StockfighterAPI do

  def venue_heartbeat(venue) do
    s = "venues/"<> venue <> "/heartbeat"
    StockfighterIO.get(s).body[:ok] == true
  end

  def list_stocks(venue) do
    s = "venues/"<> venue <> "/stocks"
    list_of_stocks = StockfighterIO.get(s).body[:symbols]
    for i <- list_of_stocks, do: i.symbol
  end

  def stock_orders(venue, stock) do
    s = "venues/"<> venue <> "/stocks/" <> stock
    StockfighterIO.get(s).body
  end

  def stock_quote(venue, stock) do
    s = "venues/"<> venue <> "/stocks/" <> stock <> "/quote"
    StockfighterIO.get(s).body
  end
end

defmodule Order do
  @derive [Poison.Encoder]

  defstruct account: "EXB123456",
            venue: "TESTEX",
            symbol: "FOOBAR",
            price: 0,
            qty: 0,
            direction: "buy",
            orderType: "immediate-or-cancel"
  
  def place(order) do
    s = "venues/"<> order.venue <> "/stocks/" <> order.symbol <> "/orders"
    orderJSON = Poison.encode! order
    r = StockfighterIO.post(s, [body: orderJSON]).body
    # IO.inspect(orderJSON)
  end
end

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
            symbol: job.symbol}
  end

  def nextSize(job) do
    togo = job.goal - job.inv
    cond do
      togo <= 0 -> {:done, :jobFilled}
      true      -> {:ok, min(togo, job.maxSize)}
    end
    
  end

  def goodPrice(job) do
    case StockfighterIO.stock_quote(job.venue, job.symbol) do
      %{ask: ask} ->  cond do
                        ask > job.maxPrice  -> {:error, {:toExpensive, ask}}
                        true                -> {:ok, ask}
                      end
      %{askDepth: _} -> {:error, :noSellers}
    end
  end

  def step(job) do
    order =
      with  {:ok, qty} <- nextSize(job),
            {:ok, ask} <- goodPrice(job),
            do: {:ok, Map.merge(newOrder(job), %{price: ask, qty: qty})}

    case order do
      {:ok, o} -> placeOrder(job, o)
      {:error, _} = err -> err
      {:done, _} = done -> done
    end
  end

  defp placeOrder(job, order) do
    %{totalFilled: tf, price: price} = Order.place order
    IO.puts "Filled #{tf} @ #{price}"
    newJob = %{job | inv: (job.inv + tf)}
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

  def stock_quote(job) do
    StockfighterAPI.stock_quote(job.venue, job.symbol)
  end

  def stock_orders(job) do
    StockfighterAPI.stock_orders(job.venue, job.symbol)
  end

end

defmodule PrepTest do

  def creatSells  do
    o = %Order{
      direction: "Sell", 
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
# #You can use the API in whatever language you'd like.  I prefer Ruby.
# require 'httparty'
# [%{"name" => "Foreign Owned Occluded Bridge Architecture Resources", "symbol" => "FOOBAR"}, %{"name" => " Owned Occluded Bridge Architecture Resources", "symbol" => "FOOBAR2"}]
# response = HTTParty.get("https://api.stockfighterIO.io/ob/api/heartbeat")
# ok = response.parsed_response["ok"] rescue false

# raise "Oh no the world is on fire!" unless ok

# %Job{account: "BAM76157239", goal: 1000000, maxPrice: 6455, maxSize: 20000, symbol: "OPI", venue: "VHEX"}