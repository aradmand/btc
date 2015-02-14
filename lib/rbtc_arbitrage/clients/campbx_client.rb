module RbtcArbitrage
  module Clients
    class CampbxClient
      include RbtcArbitrage::Client

      def exchange
        :campbx
      end

      def balance
        return @balance if @balance
        funds = interface.my_funds
        [funds["Total BTC"].to_f, funds["Total USD"].to_f]
      end

      def interface
        @interface ||= CampBX::API.new(ENV['CAMPBX_KEY'],ENV['CAMPBX_SECRET'])
      end

      def validate_env
        validate_keys :campbx_key, :campbx_secret

      end

      def trade action
        trade_mode = "Quick#{action.to_s.capitalize}"
        interface.trade_enter trade_mode, @options[:volume], price(action)
      end

      def price action
        return @price if @price
        action = {
          buy: "Best Ask",
          sell: "Best Bid",
        }[action]

        price_multiple = 0

        # TESTING - UNCOMMNET
        # puts "THERE IS TESTING CODE EFFECTING THE BUY / SELL PRICE"

        # price_multiple = if action == "Best Ask"
        #   -10
        # else
        #   10
        # end

        @price = interface.xticker[action].to_f

        @price + price_multiple
      end

      def transfer client
        if client.exchange == :coinbase_exchange
          client_address = client.address(true)
          interface.send_btc client_address, @options[:volume]
        else
          interface.send_btc client.address, @options[:volume]
        end
      end

      def address
        @address ||= interface.get_btc_address["Success"]
      end
    end
  end
end
