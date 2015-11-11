$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rbtc_arbitrage'
require 'pry'
require 'curb'
require 'active_support'
require 'json'



# Instantiate Campbx Client
campbx_client = RbtcArbitrage::Clients::CampbxClient.new


####################
# Validate Keys
####################

campbx_client.validate_env


####################
# Price
####################

campbx_buy_price = campbx_client.price(:buy)

campbx_client = RbtcArbitrage::Clients::CampbxClient.new
campbx_sell_price = campbx_client.price(:sell)

puts 'campbx_buy_price'
puts campbx_buy_price

puts 'campbx_sell_price'
puts campbx_sell_price



####################
# Order Book
####################

order_book = campbx_client.order_book
puts order_book

puts 'Top of Book (:sell): '
puts campbx_client.top_of_book_quantity(:sell)

puts 'Top of Book (:buy): '
puts campbx_client.top_of_book_quantity(:buy)


####################
# Orders (list open orders)
####################

open_orders = campbx_client.open_orders
puts "#{open_orders.size} Open Orders:"
puts open_orders


####################
# Balance
####################

campbx_client = RbtcArbitrage::Clients::CampbxClient.new
balance_result = campbx_client.balance

puts 'Campbx BTC balance'
puts balance_result.first

puts 'Campbx USD balance'
puts balance_result.second

# balance_result.count == 2



####################
# Address
####################

campbx_client = RbtcArbitrage::Clients::CampbxClient.new
campbx_address = campbx_client.address
puts 'Address for Campbx'
puts campbx_address


####################
# Transfer btc
####################

circle_client = RbtcArbitrage::Clients::CircleClient.new

# Uncomment the following line to transfer bitcoin to campbx
#circle_client.transfer(campbx_client)

# Uncomment the following line to transfer bitcoin from circle back to campbx
#campbx_client.transfer(circle_client)







####################
#  Trade
#
# Uncomment the following section to buy :volume BTC
# and then sell :volume BTC
##############################

# puts "Buying #{campbx_client.options[:volume]} BTC"
# buy = campbx_client.trade(:buy)
# if buy
#   puts "Sucessfully bought #{campbx_client.options[:volume]} BTC"
#   puts buy
# else
#   puts "Error buying BTC"
#   puts buy
# end

# puts "Selling #{campbx_client.options[:volume]} BTC"
# sell = campbx_client.trade(:sell)
# if sell == 0
#   puts "Sucessfully sold #{campbx_client.options[:volume]} BTC"
#   puts sell
# else
#   puts "Error selling BTC"
#   puts sell
# end








