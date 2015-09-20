$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'


# Instantiate Coinbase Exchange Client
coinbase_exchange_client = RbtcArbitrage::Clients::CoinbaseExchangeClient.new

# Instatiate Coinbase Client (note, different from CoinbaseExchangeClient)
coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new


####################
# Validate Keys
####################

coinbase_exchange_client.validate_env


####################
# Price
####################

coinbase_buy_price = coinbase_client.price(:buy)
coinbase_sell_price = coinbase_client.price(:sell)

puts 'coinbase_buy_price'
puts coinbase_buy_price

puts 'coinbase_sell_price'
puts coinbase_sell_price

coinbase_exchange_buy_price = coinbase_exchange_client.price(:buy)
coinbase_exchange_sell_price = coinbase_exchange_client.price(:sell)

puts 'coinbase_exchange_buy_price'
puts coinbase_exchange_buy_price

puts 'coinbase_exchange_sell_price'
puts coinbase_exchange_sell_price


####################
# Orders (list open orders)
####################

open_orders = coinbase_exchange_client.open_orders
puts "#{open_orders.size} Open Orders:"
puts open_orders


####################
# Balance
####################

balance_result = coinbase_exchange_client.balance

puts 'Coinbase Exchange BTC balance'
puts balance_result.first

puts 'Coinbase Exchange USD balance'
puts balance_result.second

balance_result.count == 2



####################
# Address
####################

coinbase_exchange_address = coinbase_exchange_client.address
puts 'Address for Coinbase (Not Coinbase Exchange)'
puts coinbase_exchange_address


# coinbase_exchange_address = coinbase_exchange_client.address(true)
# puts 'Address for Coinbase (Not Coinbase Exchange) -- transferring BTC from Coinbase to Exchange'
# puts coinbase_exchange_address



####################
# Transfer btc
####################

circle_client = RbtcArbitrage::Clients::CircleClient.new

coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new


#coinbase_client.transfer(circle_client, {volume: 0.02})

# Uncomment the following line to transfer bitcoin to coinbase
#coinbase_exchange_client.transfer(circle_client)

# Uncomment the following line to transfer bitcoin from circle back to coinbase
#circle_client.transfer(coinbase_client)





####################
#  Trade
#
# Uncomment the following section to buy :volume BTC
# and then sell :volume BTC
##############################

# puts "Buying #{coinbase_exchange_client.options[:volume]} BTC"
# buy = coinbase_exchange_client.trade(:buy)
# if buy[:order_id].present?
#   puts "Sucessfully bought #{coinbase_exchange_client.options[:volume]} BTC"
#   puts buy
# else
#   puts "Error buying BTC"
#   puts buy
# end

# puts "Selling #{coinbase_exchange_client.options[:volume]} BTC"
# sell = coinbase_exchange_client.trade(:sell)
# if sell == 0
#   puts "Sucessfully sold #{coinbase_exchange_client.options[:volume]} BTC"
# else
#   puts "Error selling BTC"
#   puts sell
# end


####################
#  Fills
#
##############################

# puts 'List of fills on coinbase exchange:'
# fills = coinbase_exchange_client.fills(buy[:order_id])
# puts fills





