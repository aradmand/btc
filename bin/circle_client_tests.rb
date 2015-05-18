$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'

require 'circle_account'


# export CIRCLE_CUSTOMER_ID=168900
# export CIRCLE_BANK_ACCOUNT_ID=186074
# export CIRCLE_CUSTOMER_SESSION_TOKEN=
# export CIRCLE_COOKIE=""
# export COINBASE_KEY=
# export COINBASE_SECRET=



# Read in list of accounts from JSON file
circle_accounts_file = File.read('lib/circle_accounts.json')
circle_account_hash = JSON.parse(circle_accounts_file)

circle_accounts_array = []

# Determine the state of each account
circle_account_hash.each do |email, account|
  circle_account = CircleAccount::CircleAccount.new(
    account['api_bank_account_id'],
    account['api_customer_id'],
    account['api_customer_session_token'],
    account['state'],
    account['withdrawn_amount_last_seven_days'],
    email
  )

  circle_account.configure_state!

  circle_accounts_array << circle_account
end

# Set only one account to active
circle_accounts_array.each do |account|
  if account.state == CircleAccount::CircleAccount::STATE_ACTIVE
    circle_accounts_array.each do |inactive_account|
      unless account == inactive_account || inactive_account.state = CircleAccount::CircleAccount::STATE_MAXED_OUT
        inactive_account.state = CircleAccount::CircleAccount::STATE_INACTIVE
      end
    end
  end
end


# # Run tests for each configured account






# Instantiate Circle Client
active_circle_account = circle_accounts_array.first
circle_client = RbtcArbitrage::Clients::CircleClient.new(circle_account: active_circle_account, volume: 0.01)

####################
# Validate Env
####################
validate_env_result = circle_client.validate_env

#validate
puts validate_env_result
validate_env_result.count == 4


####################
# Withdraw Limit
####################

withdraw_limit_seven_days = circle_client.withdraw_limit_trailing_seven_days
puts 'Withdraw Limit Trailing 7 Days:'
puts withdraw_limit_seven_days



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














