$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'

# export CIRCLE_CUSTOMER_ID=168900
# export CIRCLE_BANK_ACCOUNT_ID=186074
# export CIRCLE_CUSTOMER_SESSION_TOKEN=
# export CIRCLE_COOKIE=""
# export COINBASE_KEY=
# export COINBASE_SECRET=


# Instantiate Circle Client
circle_client = RbtcArbitrage::Clients::CircleClient.new(volume: 0.01)

####################
# Validate Env
####################
validate_env_result = circle_client.validate_env

#validate
puts validate_env_result
validate_env_result.count == 4




####################
# Balance
####################

balance_result = circle_client.balance

puts balance_result
balance_result.count == 2




####################
# Transfer btc
####################

coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new

# Uncomment the following line to transfer bitcoin to coinbase
# circle_client.transfer(coinbase_client)



####################
# Price
####################

coinbase_buy_price = coinbase_client.price(:buy)
coinbase_sell_price = coinbase_client.price(:sell)

puts 'coinbase_buy_price'
puts coinbase_buy_price

puts 'coinbase_sell_price'
puts coinbase_sell_price

circle_buy_price = circle_client.price(:buy)
circle_sell_price = circle_client.price(:sell)

puts 'circle_buy_price'
puts circle_buy_price

puts 'circle_sell_price'
puts circle_sell_price





####################
#  Trade
#
# Uncomment the following section to buy :volume BTC
# and then sell :volume BTC
##############################

binding.pry

# puts "Buying #{circle_client.options[:volume]} BTC"
# buy = circle_client.trade(:buy)
# if buy == 0
#   puts "Sucessfully bought #{circle_client.options[:volume]} BTC"
# else
#   puts "Error buying BTC"
#   puts buy
# end

# puts "Selling #{circle_client.options[:volume]} BTC"
# sell = circle_client.trade(:sell)
# if sell == 0
#   puts "Sucessfully sold #{circle_client.options[:volume]} BTC"
# else
#   puts "Error selling BTC"
#   puts sell
# end



###################
#  Address command
###################


address = circle_client.address
puts 'BTC Transfer address:'
puts address














