$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'


# Instantiate Circle Client
circle_client = RbtcArbitrage::Clients::CircleClient.new

####################
# Balance
####################

balance_result = circle_client.balance

puts balance_result
balance_result.count == 2





# Instantiate Campbx Client
campbx_client = RbtcArbitrage::Clients::CampbxClient.new

####################
# Balance
####################

balance_result = campbx_client.balance

puts 'Campbx BTC balance'
puts balance_result.first

puts 'Campbx USD balance'
puts balance_result.second

btc_balance = balance_result.first


if btc_balance > 0
  binding.pry

  campbx_client = RbtcArbitrage::Clients::CampbxClient.new(volume: btc_balance)
  #campbx_client.transfer(circle_client)
end











