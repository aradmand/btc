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
# Balance
####################

balance_result = coinbase_exchange_client.balance

puts 'Coinbase Exchange BTC balance'
puts balance_result.first

puts 'Coinbase Exchange USD balance'
puts balance_result.second

balance_result.count == 2



####################
#  Trade
#
# Uncomment the following section to buy :volume BTC
# and then sell :volume BTC
##############################

puts "Buying #{coinbase_exchange_client.options[:volume]} BTC"
buy = coinbase_exchange_client.trade(:buy)
if buy == 0
  puts "Sucessfully bought #{coinbase_exchange_client.options[:volume]} BTC"
else
  puts "Error buying BTC"
  puts buy
end

# puts "Selling #{coinbase_exchange_client.options[:volume]} BTC"
# sell = coinbase_exchange_client.trade(:sell)
# if sell == 0
#   puts "Sucessfully sold #{coinbase_exchange_client.options[:volume]} BTC"
# else
#   puts "Error selling BTC"
#   puts sell
# end








