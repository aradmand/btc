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

puts balance_result
balance_result.count == 2









