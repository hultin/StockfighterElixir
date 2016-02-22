defmodule StockfighterIOTest do
  use ExUnit.Case
  doctest StockfighterIO

  test "heartbeat" do
    assert StockfighterIO.get("heartbeat").body == %{error: "", ok: true}
    assert StockfighterIO.get("heartbeat").body[:ok] == true
    assert StockfighterIO.get("heartbeat").body.ok == true
  end

  test "venue heartbeat" do
    assert StockfighterIO.get("venues/TESTEX/heartbeat").body[:ok] == true
    assert StockfighterIO.get("venues/TESTEX/heartbeat").body[:venue] == "TESTEX"
    assert StockfighterAPI.venue_heartbeat("TESTEX") == true
  end

  test "list stocks" do
    assert StockfighterAPI.list_stocks("TESTEX") == ["FOOBAR"]
  end

  test "stock orders" do
    assert StockfighterAPI.stock_orders("TESTEX", "FOOBAR") == ["FOOBAR"]
  end

  # test "key_to_atom" do
  #   kaka = %{"error" => "", "ok" => true}
  #   assert StockfighterIO.key_to_atom(kaka) == %{error: "", ok: true}   
  # end
end
