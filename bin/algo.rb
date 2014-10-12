require 'date'
require 'pry'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'

enabled = true
MAX_PERCENT_PROFIT = 50
MIN_PERCENT_PROFIT = 2

def set_trading_parameters
  @buyer = ENV['BTC_BUYER'].try(:to_sym) || :coinbase
  @seller = ENV['BTC_SELLER'].try(:to_sym) || :bitstamp
  @volume = 0.1
end


while enabled == true

  MAX_PERCENT_PROFIT.downto(MIN_PERCENT_PROFIT) do |percent|

    start_time = Time.now
    puts
    puts "#=================="
    puts "[Timestamp - #{start_time}]"

    set_trading_parameters
    options = { buyer: @buyer, seller: @seller, volume: @volume}
    rbtc_arbitrage = RbtcArbitrage::Trader.new(options)

    puts "rbtc_arbitrage command:"
    puts "`rbtc --seller #{@seller} --buyer #{@buyer} --volume #{@volume} --cutoff #{percent}`"

    btc_balance, usd_balance = rbtc_arbitrage.get_buyer_balance
    puts "[ Balance on buyer (#{@buyer}) exchange: (#{usd_balance} in USD) (#{btc_balance} in BTC) ]"

    btc_balance, usd_balance = rbtc_arbitrage.get_seller_balance
    puts "[ Balance on seller (#{@seller}) exchange: (#{usd_balance} in USD) (#{btc_balance} in BTC) ]"

    buyer_price = rbtc_arbitrage.fetch_buyer_price
    puts "[ Ask on buyer (#{@buyer}) exchange: (#{buyer_price} in dollars) ]"

    seller_price = rbtc_arbitrage.fetch_seller_price
    puts "[ Bid on sell (#{@seller}) exchange: (#{seller_price} in dollars) ]"

    # Fetching exchange rates
    # Coinbase (Ask): $363.18
    # Bitstamp (Bid): $358.24
    # buying 0.5 btc at Coinbase for $182.68
    # selling 0.5 btc at Bitstamp for $178.05
    # profit: $-4.63 (-2.54%) is below cutoff of 3%

    end_time = Time.now
    puts "[Timestamp - #{end_time}]"
    puts "[Elapsed time - #{end_time - start_time}]"
    puts "#=================="
    puts

  end
  break
end




