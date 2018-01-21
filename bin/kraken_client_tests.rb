$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'

# Instantiate Kraken Client
kraken_client = RbtcArbitrage::Clients::KrakenClient.new


####################
# Validate Keys
####################

kraken_client.validate_env


####################
# Price
####################

kraken_buy_price = kraken_client.price(:buy)
kraken_sell_price = kraken_client.price(:sell)

puts 'kraken_buy_price'
puts kraken_buy_price

puts 'kraken_sell_price'
puts kraken_sell_price


####################
# Orders (list open orders)
####################

open_orders = kraken_client.open_orders
puts "#{open_orders.size} Open Orders:"
puts open_orders

####################
# Balance
####################

balance_result = kraken_client.balance

puts 'Kraken BTC balance'
puts balance_result.first

puts 'Kraken USD balance'
puts balance_result.second

balance_result.count == 2


####################
# Address
####################

kraken_address = kraken_client.address
puts 'Address for Kraken:'
puts kraken_address

####################
# Transfer btc
####################


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
# if buy == 0
#   puts "Sucessfully bought #{coinbase_exchange_client.options[:volume]} BTC"
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








