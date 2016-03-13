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
    # |> IO.inspect
  end

  def process_request_headers(headers) do
    authKey = StockfighterAuthKey.getKey
    headers ++ ["X-Starfighter-Authorization": authKey]
  end
end