# Gamma Algo
#
# Features of this strategey include:
# => Before trading, the algo will check to see if any open orders
#  exist on either exchange.  If so, the algo will pause and not continue
#  trading until there are 0 open orders.
#
# => The 'volume' quantity of the selling exchange will be matched to the current
#  quantity of the top of book 'Bid' order on the sell exchange (if the order quantity
#  is less than the volume of BTC we have on hand at the exchange).  This should help
#  guard against orders sitting open due to non-matches for AON

require 'date'
require 'pry'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'

@accumulated_profit_in_cents = 0
enabled = true
profit = 0

MIN_PERCENT_PROFIT = 0.5
MAX_TOP_OF_BOOK_QUANTITY_TO_TRADE = 0.25


def set_trading_parameters
  @buyer = ENV['BTC_BUYER'].try(:to_sym) || :campbx
  @seller = ENV['BTC_SELLER'].try(:to_sym) || :coinbase_exchange
  @volume = 0.01

  args_hash = Hash[*ARGV]
  @live = args_hash['--live'] == 'true'
  @step = args_hash['--step'] == 'true'
end

def trade(buy_exchange, sell_exchange)
  begin
    percent = MIN_PERCENT_PROFIT
    sleep(1.0)
    puts
    puts
    puts

    start_time = Time.now

    puts "#=================="
    puts "[Timestamp - #{start_time}]"

    # If CampBx is the sell exchange, try to match the quantity of
    # top of book to increase the chances of a match in the event of
    # AON order types.
    if sell_exchange == :campbx

    end

    options = { buyer: buy_exchange, seller: sell_exchange, volume: @volume, cutoff: percent, verbose: true}

    ####### This turns on live trading #####
    if @live == true
      options.merge!({live: true})
    end
    if options.has_key?(:live)
      puts '*** LIVE TRADING MODE IS SET TO TRUE! ***'
    end
    ########################################

    rbtc_arbitrage = RbtcArbitrage::Trader.new(options)


    # If CampBx is the sell exchange, try to match the quantity of
    # top of book to increase the chances of a match in the event of
    # AON order types.
    if sell_exchange == :campbx
      buyer_btc_balance, buyer_usd_balance = rbtc_arbitrage.get_buyer_balance
      seller_btc_balance, seller_usd_balance = rbtc_arbitrage.get_seller_balance

      top_of_book_quantity = rbtc_arbitrage.sell_client.top_of_book_quantity(:sell)
      if top_of_book_quantity &&
        top_of_book_quantity <= buyer_btc_balance &&
        top_of_book_quantity <= seller_btc_balance &&
        top_of_book_quantity <= MAX_TOP_OF_BOOK_QUANTITY_TO_TRADE

        new_volume = top_of_book_quantity
        options.merge!({volume: new_volume})

        rbtc_arbitrage = RbtcArbitrage::Trader.new(options)
      end
    end

    command = "rbtc --seller #{options[:seller]} --buyer #{options[:buyer]} --volume #{options[:volume]} --cutoff #{options[:cutoff]}"

    puts "rbtc_arbitrage command:"
    puts command

    btc_balance, usd_balance = rbtc_arbitrage.get_buyer_balance
    puts "[ Balance on buyer (#{buy_exchange}) exchange: (#{usd_balance} in USD) (#{btc_balance} in BTC) ]"

    btc_balance, usd_balance = rbtc_arbitrage.get_seller_balance
    puts "[ Balance on seller (#{sell_exchange}) exchange: (#{usd_balance} in USD) (#{btc_balance} in BTC) ]"

    buyer_price = rbtc_arbitrage.fetch_buyer_price
    puts "[ Ask on buyer (#{buy_exchange}) exchange: (#{buyer_price} in dollars) ]"

    seller_price = rbtc_arbitrage.fetch_seller_price
    puts "[ Bid on sell (#{sell_exchange}) exchange: (#{seller_price} in dollars) ]"
binding.pry
    profit_dollars, profit_percent = rbtc_arbitrage.get_profit
    puts "Profit: $#{profit_dollars} --> #{profit_percent}%"

    if profit_percent > percent
    puts "PROFITABLE TRADE!"
    @accumulated_profit_in_cents += (profit_dollars * 100)
    end
    puts "ACCUMULATED PROFIT: #{@accumulated_profit_in_cents / 100.0}"

    end_time = Time.now
    puts "[Timestamp - #{end_time}]"
    puts "[Elapsed time - #{end_time - start_time}]"
    puts

    puts "\t---Executing command---"
    start_time = Time.now
    rbtc_arbitrage.trade
    end_time = Time.now
    puts "[Elapsed time - #{end_time - start_time}]"
    puts "\t---Done excecuting command---"
    puts "#=================="

  rescue Exception => e
    puts " *** Exception has occured *** "
    puts e.message
    puts "************"
  end

  [profit_dollars, profit_percent, rbtc_arbitrage]
end

def flip_exchanges(exchange_a, exchange_b)
  [exchange_b, exchange_a]
end

def no_open_orders?(exchange_a, exchange_b)
  exchange_a.open_orders.size == 0 &&
    exchange_b.open_orders.size == 0
end

set_trading_parameters
exchange_1 = @buyer
exchange_2 = @seller

while enabled == true
  set_trading_parameters
  if profit > 0
    profit, profit_percent = trade(exchange_1, exchange_2)
  else
    exchange_1, exchange_2 = flip_exchanges(exchange_1, exchange_2)
  end

  profit, profit_percent, rbtc_arbitrage = trade(exchange_1, exchange_2)

  if @step && profit_percent >= MIN_PERCENT_PROFIT
    binding.pry
  end
binding.pry
  while profit_percent >= MIN_PERCENT_PROFIT &&
    no_open_orders?(rbtc_arbitrage.buy_client, rbtc_arbitrage.sell_client) == false

    open_order_sleep = 10.0
    puts "*** Open orders detected on exchanges! Re-checking in #{open_order_sleep} seconds. ***"
    sleep(open_order_sleep)
  end

  #enabled = false
end
