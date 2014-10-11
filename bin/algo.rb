require 'rbtc_arbitrage'
require 'date'

enabled = true
MAX_PERCENT_PROFIT = 50
MIN_PERCENT_PROFIT = 2

while enabled == true

  MAX_PERCENT_PROFIT.downto(MIN_PERCENT_PROFIT) do |percent|
    start_time = Time.now
    puts
    puts "#=================="
    puts "[Timestamp - #{start_time}]"

    #rbtc_arbitrage command:
    #rbtc --seller bitstamp --buyer coinbase --volume 0.5 --cutoff 3

    # [ Balance on buyer (EXCHANGE_NAME) exchange: (in dollars) ]

    # [ Balance on sell (EXCHANGE_NAME) exchange: (in dollars) ]

    # [ Ask on buyer (EXCHANGE_NAME) exchange: (in dollars) ]

    # [ Bid on sell (EXCHANGE_NAME) exchange: (in dollars) ]

    # Fetching exchange rates
    # Coinbase (Ask): $363.18
    # Bitstamp (Bid): $358.24
    # buying 0.5 btc at Coinbase for $182.68
    # selling 0.5 btc at Bitstamp for $178.05
    # profit: $-4.63 (-2.54%) is below cutoff of 3%

    end_time = Time.now
    puts "[Timestamp - #{end_time}]"
    puts "[Elapsed time - #{end_time - start_time}]"
    puts "#=================="
    puts


  end
  break
end


