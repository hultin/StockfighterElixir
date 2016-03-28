alias StockfighterAPI.{Order, OrderStatus}

defmodule Stockfighter do
  use Application

  def start(_type, _args) do
    :observer.start
    # OrderWorker.Supervisor.start_link
    OrderRecordSup.start_link(:nrOne)
  end

  def ttt, do: OrderRecord.newOrder(:nrOne, OrderRecord.tOrder)
end





# #You can use the API in whatever language you'd like.  I prefer Ruby.
# require 'httparty'
# [%{"name" => "Foreign Owned Occluded Bridge Architecture Resources", "symbol" => "FOOBAR"}, %{"name" => " Owned Occluded Bridge Architecture Resources", "symbol" => "FOOBAR2"}]
# response = HTTParty.get("https://api.stockfighterIO.io/ob/api/heartbeat")
# ok = response.parsed_response["ok"] rescue false

# raise "Oh no the world is on fire!" unless ok

# %Job{account: "BAM76157239", goal: 1000000, maxPrice: 6455, maxSize: 20000, symbol: "OPI", venue: "VHEX"}
# %Job{account: "CB95531829", goal: 1000000, maxPrice: 6455, maxSize: 20000, symbol: "EUHE", venue: "TEWUEX"}
# %Job{account: "SMB53549881", goal: 1000000, maxPrice: 4315, maxSize: 20000, symbol: "DLH", venue: "CHKBEX"}
# defmodule Stock do
#   defstruct account: "EXB123456",
#             venue: "TESTEX",
#             symbol: "FOOBAR",

# end

# defmodule RecordMovment do
#   def rec %Stock{} do
#     IO.inspect 
# end

# %Job{account: "EXB123456", goal: 100000, inv: 0, maxPrice: 4315, maxSize: 100, symbol: "FOOBAR", venue: "TESTEX"}
# j = %Job{account: "BN50535469", goal: 1000000, inv: 100, maxPrice: 4315, maxSize: 20000, symbol: "SLC", venue: "IBVEX"}   