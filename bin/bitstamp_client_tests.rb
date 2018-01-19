$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'

# Instantiate Bitstamp Client
bitstamp_client = RbtcArbitrage::Clients::BitstampClient.new


####################
# Validate Keys
####################

bitstamp_client.validate_env


####################
# Price
####################

bitstamp_buy_price = bitstamp_client.price(:buy)
bitstamp_sell_price = bitstamp_client.price(:sell)

puts 'bitstamp_buy_price'
puts bitstamp_buy_price

puts 'bitstamp_sell_price'
puts bitstamp_sell_price


####################
# Orders (list open orders)
####################

binding.pry

open_orders = bitstamp_client.open_orders
puts "#{open_orders.size} Open Orders:"
puts open_orders

####################
# Balance
####################

balance_result = bitstamp_client.balance

puts 'Bitstamp BTC balance'
puts balance_result.first

puts 'Bitstamp USD balance'
puts balance_result.second

balance_result.count == 2


####################
# Address
####################

binding.pry
binding.pry

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








