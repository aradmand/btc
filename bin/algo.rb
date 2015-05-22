# Epsilon Algo
#
# This Algorithm is optimized for arbitrage trading between the circle and
# coinbase_exchange exchanges.
#
# Features of this strategey include:
# => This is the first strategy capable of trading multiple circle accounts
# => Since Circle limits our withdraws to $5,000 / week, this strategy is designed
# => to use multiple circle accounts to stay under this limit. Of Note:
#
# => circle_accounts.json
# => This file has been added as a way to dynamically configure Circle Accounts
# => Circle env variables are no longer needed to configure circle_client, as all
# => values come from this file
#
# => circle_account.rb
# => This file has been added to be the in-memory representation of a circle_account.
# => It will house all necessary env variables needed to make api requests for the
# => given account.

# THE ALGORITHM:
  # The algo will read in the circle_accounts.json file to find the first account
  # eligible to be traded and set it to active.

  # All other accounts will be marked as either INACTIVE or MAXED_OUT

  # The active account will be traded until it becomes MAXED_OUT

  # When it is MAXED_OUT, the algo will repeat the process and scan through
  # theh list of eligible accounts in circle_accounts.json to choose the next active
  # account to trade.


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

@accumulated_profit_in_cents = 0
enabled = true
profit = 0

MIN_PERCENT_PROFIT = 0.61
MAX_TOP_OF_BOOK_QUANTITY_TO_TRADE = 0.5


def set_trading_parameters
  @buyer = ENV['BTC_BUYER'].try(:to_sym) || :circle
  @seller = ENV['BTC_SELLER'].try(:to_sym) || :coinbase_exchange
  @volume = 0.4

  args_hash = Hash[*ARGV]
  @live = args_hash['--live'] == 'true'
  @step = args_hash['--step'] == 'true'
end

def trade(buy_exchange, sell_exchange, circle_buy_client, circle_sell_client)
  error_message = ''
  begin
    percent = MIN_PERCENT_PROFIT
    sleep(5.0)
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

    profit_dollars, profit_percent = rbtc_arbitrage.get_profit
    puts "Profit: $#{profit_dollars} --> #{profit_percent}%"

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

    if profit_percent > percent
      puts "PROFITABLE TRADE!"
      @accumulated_profit_in_cents += (profit_dollars * 100)
    end

  rescue SecurityError => e
    puts " *** Exception has occured *** "
    puts e.message
    puts "************"
    error_message = e.message
  end

  [profit_dollars, profit_percent, rbtc_arbitrage, error_message]
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

# Read in circle_accounts.json to get first ACTIVE account
active_circle_account = CircleAccount::CircleAccount.find_active_account

while enabled == true
  set_trading_parameters
  if profit > 0
    # Do Nothing
  else
    if exchange_1 == :circle
      exchange_1, exchange_2 = flip_exchanges(exchange_1, exchange_2)
    else
      exchange_1, exchange_2 = flip_exchanges(exchange_1, exchange_2)
    end
  end

  if exchange_1 == :circle
    profit, profit_percent, rbtc_arbitrage, error_message = trade(exchange_1, exchange_2, active_circle_account, nil)
  else
    profit, profit_percent, rbtc_arbitrage, error_message = trade(exchange_1, exchange_2, nil, active_circle_account)
  end

  if @step && profit_percent >= MIN_PERCENT_PROFIT
    binding.pry
  end

  while profit_percent >= MIN_PERCENT_PROFIT &&
    no_open_orders?(rbtc_arbitrage.buy_client, rbtc_arbitrage.sell_client) == false

    open_order_sleep = 10.0
    puts "*** Open orders detected on exchanges! Re-checking in #{open_order_sleep} seconds. ***"
    sleep(open_order_sleep)
  end

  if profit_percent >= MIN_PERCENT_PROFIT && !exception_due_to_insufficient_funds?(error_message)
    # Sleep after profitable trade to avoid getting flagged for
    # frequent trades on Circle
    sleep_time = (1..2).to_a.sample * 60
    puts
    puts "******"
    puts "Waiting #{sleep_time / 60} mins (#{sleep_time} seconds) after profitable trade to resume trading ..."
    puts "******"
    puts

    sleep(sleep_time)
  end

  #enabled = false
end
