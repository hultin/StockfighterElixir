defmodule StockfighterAPI.CheckVenueIsUp do
  defstruct ok: False,
            venue: ""
  use ExConstructor

  def get(%{venue: v}), do: get(v)
  def get(venue) do
    s = "venues/"<> venue <> "/heartbeat"
    StockfighterIO.get(s).body
    |> new
  end

  def is_up?(%{venue: v}), do: get(v)
  def is_up?(venue) do
    %StockfighterAPI.CheckVenueIsUp{ok: state} = get(venue)
    state == true
  end

end


defmodule StockfighterAPI.CheckAPIIsUp do
  defstruct ok: false,
            error: ""
  use ExConstructor

  def get do
    s = "heartbeat"
    StockfighterIO.get(s).body
    |> new
  end

  def is_up? do
    %StockfighterAPI.CheckAPIIsUp{ok: state} = get
    state == true
  end
end


defmodule StockfighterAPI.Symbol do
  defstruct name: "",
            symbol: ""
  use ExConstructor

  def new_fromList(listOfSymbols) do
    if is_list(listOfSymbols) do 
      Enum.map(listOfSymbols, fn(x) -> new(x) end)
    else
      []
    end
  end
end

defmodule StockfighterAPI.StockOnVenue do
  defstruct ok: false,
            symbols: []

  def new(map_or_kwlist) do
    s = ExConstructor.populate_struct(%__MODULE__{}, map_or_kwlist)
    symbols = StockfighterAPI.Symbol.new_fromList(s.symbols)
    %__MODULE__{s | symbols: symbols}
  end

  def get(%{venue: v}), do: get(v)
  def get(venue) do
    s = "venues/"<> venue <> "/stocks"
    StockfighterIO.get(s).body |> new
  end
end

defmodule Offer do
  defstruct isBuy: nil, 
            price: 0,
            qty: 0
  use ExConstructor

  def new_fromList(listOfOffers) do
    if is_list(listOfOffers) do 
      Enum.map(listOfOffers, fn(x) -> Offer.new(x) end)
    else
      []
    end
  end
end

defmodule StockfighterAPI.Orderbook do
  defstruct ok: false,
            symbol: "",
            venue: "",
            ts: "",
            asks: [],
            bids: []

  @spec new(ExConstructor.map_or_kwlist) :: %__MODULE__{}
  def new(map_or_kwlist) do
    s = ExConstructor.populate_struct(%__MODULE__{}, map_or_kwlist)
    asks = Offer.new_fromList(s.asks)
    bids = Offer.new_fromList(s.bids)
    %__MODULE__{s | asks: asks, bids: bids}
  end

  def get(%{venue: v, symbol: s}), do: get(v, s)
  def get(venue, symbol) do
    s = "venues/"<> venue <> "/stocks/" <> symbol
    StockfighterIO.get(s).body |> new
  end
end


defmodule StockfighterAPI.StockQuote do
  defstruct ok: false,
            symbol: "",
            venue: "",
            bid: 0,         # best price currently bid for the stock
            ask: 0,         # best price currently offered for the stock
            bidSize: 0,     # aggregate size of all orders at the best bid
            askSize: 0,     # aggregate size of all orders at the best ask
            bidDepth: 0,    # aggregate size of *all bids*
            askDepth: 0,    # aggregate size of *all asks*
            last: 0,        # price of last trade
            lastSize: 0,    # quantity of last trade
            lastTrade: "",  # timestamp of last trade
            quoteTime: ""   # ts we last updated quote at (server-side)

  use ExConstructor

  def get(%{venue: v, symbol: s}), do: get(v, s)
  def get(venue, stock) do
    s = "venues/"<> venue <> "/stocks/" <> stock <> "/quote"
    StockfighterIO.get(s).body
    |> new
  end
end

defmodule StockfighterAPI.OrderStatus do
  defmodule Fills do
    defstruct price: 0,
              qty: 0,
              ts: ""
    use ExConstructor

    def new_fromList(listOfOffers) do
      if is_list(listOfOffers) do 
        Enum.map(listOfOffers, fn(x) -> Fills.new(x) end)
      else
        []
      end
    end
  end

  defstruct ok: false,
            symbol: "",
            venue: "",
            direction: "",
            originalQty: 0,
            qty: 0,   # this is the quantity *left outstanding*
            price: 0, # the price on the order -- may not match that of fills!
            orderType: "",
            id: 0, # guaranteed unique *on this venue*
            account: "",
            ts: "", # ISO-8601 timestamp for when we received order
            fills: [], # may have zero or multiple fills.  Note this order presumably has a total of 80 shares worth 
            totalFilled: 0,
            open: false
 
  @spec new(ExConstructor.map_or_kwlist) :: %__MODULE__{}
  def new(map_or_kwlist) do
    s = ExConstructor.populate_struct(%__MODULE__{}, map_or_kwlist)
    fills = Fills.new_fromList(s.fills)
    %__MODULE__{s | fills: fills}
  end

  def get(%{venue: v, symbol: s, id: id}), do: get(v, s, id)
  def get(venue, stock, orderID) do
    s = "venues/"<> venue <> "/stocks/" <> stock <> "/orders/" <> to_string(orderID)
    StockfighterIO.get(s).body
    |> new
  end

  def cancel(%{venue: v, symbol: s, id: id}), do: cancel(v, s, id)
  def cancel(venue, stock, orderID) do
    s = "venues/"<> venue <> "/stocks/" <> stock <> "/orders/" <> to_string(orderID)
    StockfighterIO.delete(s).body
    |> new
  end

  def filled?(%{originalQty: oq, totalFilled: tf}), do: tf >= oq
end

defmodule StockfighterAPI.Order do
  @derive [Poison.Encoder]
  
  defstruct account: "",
            venue: "",
            symbol: "",
            price: 0,
            qty: 0,
            direction: "buy",
            orderType: "immediate-or-cancel"
  
  def place(order) do
    s = "venues/"<> order.venue <> "/stocks/" <> order.symbol <> "/orders"
    orderJSON = Poison.encode! order
    StockfighterIO.post(s, [body: orderJSON]).body
    |> StockfighterAPI.OrderStatus.new
  end
end
