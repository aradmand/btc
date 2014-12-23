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
circle_client = RbtcArbitrage::Clients::CircleClient.new

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

circle_client = RbtcArbitrage::Clients::CircleClient.new

coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new

# Uncomment the following line to transfer bitcoin to coinbase
 circle_client.transfer(coinbase_client)


