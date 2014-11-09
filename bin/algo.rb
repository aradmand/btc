require 'date'
require 'pry'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'

@accumulated_profit_in_cents = 0
enabled = true
profit = 0

MIN_PERCENT_PROFIT = 0.3


def set_trading_parameters
  @buyer = ENV['BTC_BUYER'].try(:to_sym) || :bitstamp
  @seller = ENV['BTC_SELLER'].try(:to_sym) || :campbx
  @volume = 0.1
end

def trade(buy_exchange, sell_exchange)
  begin
    percent = MIN_PERCENT_PROFIT
    sleep(2.0)
    puts
    puts
    puts

    start_time = Time.now

    puts "#=================="
    puts "[Timestamp - #{start_time}]"

    options = { buyer: buy_exchange, seller: sell_exchange, volume: @volume, cutoff: percent, verbose: true}
    rbtc_arbitrage = RbtcArbitrage::Trader.new(options)

    command = "rbtc --seller #{sell_exchange} --buyer #{buy_exchange} --volume #{@volume} --cutoff #{percent}"

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

  profit_dollars
end

def flip_exchanges(exchange_a, exchange_b)
  [exchange_b, exchange_a]
end

set_trading_parameters
exchange_1 = @buyer
exchange_2 = @seller

while enabled == true
  set_trading_parameters
  if profit > 0
    profit = trade(exchange_1, exchange_2)
  else
    exchange_1, exchange_2 = flip_exchanges(exchange_1, exchange_2)
  end
  sleep(1.0 / 3.0)
  profit = trade(exchange_1, exchange_2)
end




