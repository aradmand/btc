# Iota Algo
#
# This Algorithm is optimized for arbitrage trading between
# coinbase_exchange and Kraken exchanges.
#
# Basic arbitrage strategy, always choosing coinbase_exchange as the buyer
# and leaving Kraken exchange as the seller.
#
#  TRADING NOTES:
# => Before trading, the algo will check to see if any open orders
#  exist on the coinbase_exchange exchange.  If so, the algo will pause and not continue
#  trading until there are 0 open orders.
#
# => Before trading, BTC balances on either exchange will be checked to ensure
#   there are enough funds available to trade.
#
#
# => Profit is only recorded against the accumulated total
#   if there was enough balance in each of the exchanges and the trade was
#   actually executed.

require 'date'
require 'pry'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'circle_account'

@accumulated_profit_in_cents = 0
enabled = true
profit = 0

MIN_PERCENT_PROFIT = 0.5
MAX_TOP_OF_BOOK_QUANTITY_TO_TRADE = 0.5


def set_trading_parameters
  @buyer = ENV['BTC_BUYER'].try(:to_sym) || :coinbase_exchange
  @seller = ENV['BTC_SELLER'].try(:to_sym) || :kraken
  @volume = 0.002

  args_hash = Hash[*ARGV]
  @live = args_hash['--live'] == 'true'
  @step = args_hash['--step'] == 'true'
end

def trade(buy_exchange, sell_exchange, circle_buy_client, circle_sell_client)
  error_message = ''
  begin
    percent = MIN_PERCENT_PROFIT
    puts
    puts
    puts

    start_time = Time.now

    puts "#=================="
    puts "[Timestamp - #{start_time}]"

    options = {
      buyer: buy_exchange,
      seller: sell_exchange,
      volume: @volume,
      cutoff: percent,
      verbose: true
    }#.merge(set_circle_account_hash)

    ####### This turns on live trading #####
    if @live == true
      options.merge!({live: true})
    end
    if options.has_key?(:live)
      puts '*** LIVE TRADING MODE IS SET TO TRUE! ***'
    end
    ########################################

    rbtc_arbitrage = RbtcArbitrage::Trader.new(options)

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

    profit_dollars, profit_percent = rbtc_arbitrage.get_profit
    puts "Profit: $#{profit_dollars} --> #{profit_percent}%"

    buyer_depth_to_cover = rbtc_arbitrage.buyer_depth_to_cover?(options[:volume])
    puts "Buyer Depth to Cover?: #{buyer_depth_to_cover}"

    puts "ACCUMULATED PROFIT: #{@accumulated_profit_in_cents / 100.0}"

    end_time = Time.now
    puts "[Timestamp - #{end_time}]"
    puts "[Elapsed time - #{end_time - start_time}]"
    puts

    if buyer_depth_to_cover == true || @live == false
      puts "\t---Executing command---"
      start_time = Time.now
      rbtc_arbitrage.trade
      end_time = Time.now
      puts "[Elapsed time - #{end_time - start_time}]"
      puts "\t---Done excecuting command---"
      puts "#=================="

      if profit_percent > percent
        puts "PROFITABLE TRADE!"
        @accumulated_profit_in_cents += (profit_dollars * 100)

        live_mode = @live == true
        log_profit_and_loss_data(buyer_price, seller_price, profit_dollars, profit_percent, live_mode)
      end
    end

  rescue SecurityError => e
    puts " *** Exception has occured *** "
    puts e.message
    puts "************"
    error_message = e.message
  end

  [profit_dollars, profit_percent, rbtc_arbitrage, error_message]
end

def log_profit_and_loss_data(buyer_price, seller_price, profit_dollars, profit_percent, live_mode)
  @log_time ||= Time.now.strftime("%Y_%m_%d")
  filename = "/Users/jupiter/tmp/btc_logs/profit_loss_#{live_mode == true ? 'LIVE' : 'test'}_#{@log_time}.csv"

  #Place Header if we're running through for the first time
  @header_placed ||= nil

  time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  CSV.open( filename, 'ab' ) do |writer|
      unless @header_placed == true
        @header_placed = true
        writer << ['Timestamp', 'Buyer Price', 'Seller Price', 'Profit', 'Profit Percent']
      end
      writer << [time, buyer_price, seller_price, profit_dollars, profit_percent]
  end
end

def flip_exchanges(exchange_a, exchange_b)
  [exchange_b, exchange_a]
end

def no_open_orders?(exchange_a, exchange_b)
  exchange_a.open_orders.size == 0 &&
    exchange_b.open_orders.size == 0
end

def exception_due_to_insufficient_funds?(message)
  message == "Not enough funds. Exiting."
end

set_trading_parameters
exchange_1 = @buyer
exchange_2 = @seller
active_circle_account = nil

while enabled == true
  puts "Pausing for 10 seconds ..."
  sleep(10.0)

  set_trading_parameters

  profit, profit_percent, rbtc_arbitrage, error_message = trade(exchange_1, exchange_2, nil, nil)

  if @step && profit_percent >= MIN_PERCENT_PROFIT
    binding.pry
  end

  while profit_percent >= MIN_PERCENT_PROFIT &&
    no_open_orders?(rbtc_arbitrage.buy_client, rbtc_arbitrage.sell_client) == false

    open_order_sleep = 10.0
    puts "*** Open orders detected on exchanges! Re-checking in #{open_order_sleep} seconds. ***"
    sleep(open_order_sleep)
  end
end
