defmodule StockfighterIOTest do
  use ExUnit.Case
  doctest StockfighterIO

  # test "heartbeat" do
  #   assert StockfighterIO.get("heartbeat").body == %{error: "", ok: true}
  #   assert StockfighterIO.get("heartbeat").body[:ok] == true
  #   assert StockfighterIO.get("heartbeat").body.ok == true
  # end

  # test "venue heartbeat" do
  #   assert StockfighterIO.get("venues/TESTEX/heartbeat").body[:ok] == true
  #   assert StockfighterIO.get("venues/TESTEX/heartbeat").body[:venue] == "TESTEX"
  #   assert StockfighterAPI.venue_heartbeat("TESTEX") == true
  # end

  # test "list stocks" do
  #   assert StockfighterAPI.list_stocks("TESTEX") == ["FOOBAR"]
  # end

  # test "stock orders" do
  #   assert StockfighterAPI.stock_orders("TESTEX", "FOOBAR") == ["FOOBAR"]
  # end

  # test "key_to_atom" do
  #   kaka = %{"error" => "", "ok" => true}
  #   assert StockfighterIO.key_to_atom(kaka) == %{error: "", ok: true}   
  # end
  test "StockfighterAPI.Symbol" do
    json = %{"name" => "kaka", "symbol" => "ka"}
    t = StockfighterAPI.Symbol.new(json)
    assert t == %StockfighterAPI.Symbol{name: "kaka", symbol: "ka"}
  end

  test "StockOnVenue" do
    json = "{
              \"ok\": true,
              \"symbols\": [
                {
                  \"name\": \"Foreign Owned Occulmancy\", 
                 \"symbol\": \"FOO\"
                },
                {
                  \"name\": \"Best American Ricecookers\",
                  \"symbol\": \"BAR\"
                },
                {
                  \"name\": \"Badly Aliased Zebras\", 
                  \"symbol\": \"BAZ\"
                }
              ]
            }"
    json
    |> Poison.decode! 
    |> StockfighterAPI.StockOnVenue.new
    |> IO.inspect
  end 


  test "offer" do
    json = %{"isBuy" => true, "price" => 1000, "qty" => 10}
    t = Offer.new(json)
    assert t == %Offer{isBuy: true, price: 1000, qty: 10}
  end


  test "nestedOffers" do
    json = [%{"isBuy" => true, "price" => 1000, "qty" => 10},
            %{"isBuy" => false, "price" => 1000, "qty" => 10},
            %{"isBuy" => true, "price" => 44, "qty" => 10}]
    ref_struct = [%Offer{isBuy: true, price: 1000, qty: 10},
                  %Offer{isBuy: false, price: 1000, qty: 10},
                  %Offer{isBuy: true, price: 44, qty: 10}]
    assert ref_struct == Offer.new_fromList(json)
    assert [] == Offer.new_fromList(nil)
  end

  test "nested structs" do
    json = %{"asks" => nil, "bids" => [%{"isBuy" => true, "price" => 1000, "qty" => 10}, %{"isBuy" => true, "price" => 1000, "qty" => 10}, %{"isBuy" => true, "price" => 1000, "qty" => 10}], "ok" => true, "symbol" => "FOOBAR", "ts" => "2016-02-25T19:14:38.698119497Z", "venue" => "TESTEX"}
    ref_nested = %StockfighterAPI.Orderbook{
                    asks: [],
                    bids: [ %Offer{isBuy: true, price: 1000, qty: 10},
                            %Offer{isBuy: true, price: 1000, qty: 10},
                            %Offer{isBuy: true, price: 1000, qty: 10}],
                    ok: true, 
                    symbol: "FOOBAR",
                    ts: "2016-02-25T19:14:38.698119497Z",
                    venue: "TESTEX"}
    assert ref_nested == StockfighterAPI.Orderbook.new(json)
  end

  test "heartbeat" do
    assert StockfighterAPI.CheckVenueIsUp.is_up?("TESTEX") == true
    assert StockfighterAPI.CheckAPIIsUp.is_up? == true
  end

  test "get Orderbook" do
    # assert StockfighterAPI.Orderbook.get(1,2) == "fis"
    # IO.inspect StockfighterAPI.Orderbook.get("TESTEX", "FOOBAR")
    # IO.inspect StockfighterAPI.StockQuote.get("TESTEX", "FOOBAR")
    # IO.inspect StockfighterAPI.StockOnVenue.get("TESTEX")
    # IO.inspect StockfighterAPI.CheckVenueIsUp.get("TESTEX")
  end
end
