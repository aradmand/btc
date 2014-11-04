require 'date'
require 'pry'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'

accumulated_profit_in_cents = 0
enabled = true

MIN_PERCENT_PROFIT = 0.5


def set_trading_parameters
  @buyer = ENV['BTC_BUYER'].try(:to_sym) || :bitstamp
  @seller = ENV['BTC_SELLER'].try(:to_sym) || :campbx
  @volume = 0.1
end


while enabled == true
    percent = MIN_PERCENT_PROFIT
    sleep(2.0)
    puts
    puts
    puts

    start_time = Time.now

    puts "#=================="
    puts "[Timestamp - #{start_time}]"

    set_trading_parameters
    options = { buyer: @buyer, seller: @seller, volume: @volume, cutoff: percent, verbose: true}
    rbtc_arbitrage = RbtcArbitrage::Trader.new(options)

    command = "rbtc --seller #{@seller} --buyer #{@buyer} --volume #{@volume} --cutoff #{percent}"

    puts "rbtc_arbitrage command:"
    puts command

    btc_balance, usd_balance = rbtc_arbitrage.get_buyer_balance
    puts "[ Balance on buyer (#{@buyer}) exchange: (#{usd_balance} in USD) (#{btc_balance} in BTC) ]"

    btc_balance, usd_balance = rbtc_arbitrage.get_seller_balance
    puts "[ Balance on seller (#{@seller}) exchange: (#{usd_balance} in USD) (#{btc_balance} in BTC) ]"

    buyer_price = rbtc_arbitrage.fetch_buyer_price
    puts "[ Ask on buyer (#{@buyer}) exchange: (#{buyer_price} in dollars) ]"

    seller_price = rbtc_arbitrage.fetch_seller_price
    puts "[ Bid on sell (#{@seller}) exchange: (#{seller_price} in dollars) ]"

    profit_dollars, profit_percent = rbtc_arbitrage.get_profit
    puts "Profit: $#{profit_dollars} --> #{profit_percent}%"

    if profit_percent > percent
      puts "PROFITABLE TRADE!"
      accumulated_profit_in_cents += (profit_dollars * 100)
      puts "ACCUMULATED PROFIT: #{accumulated_profit_in_cents / 100.0}"
    end

    end_time = Time.now
    puts "[Timestamp - #{end_time}]"
    puts "[Elapsed time - #{end_time - start_time}]"
    puts

    puts "\t---Executing command---"
    start_time = Time.now
    output = `#{command}`
    end_time = Time.now
    puts output
    puts "[Elapsed time - #{end_time - start_time}]"
    puts "\t---Done excecuting command---"
    puts "#=================="

end




