module RbtcArbitrage
  module Clients
    class CircleClient
      include RbtcArbitrage::Client

      # return a symbol as the name
      # of this exchange
      def exchange
        :circle
      end

      # Returns an array of Floats.
      # The first element is the balance in BTC;
      # The second is in USD.
      def balance
      end

      def interface
      end

      # Configures the client's API keys.
      def validate_env
        validate_keys :circle_customer_session_token, :circle_cookie
      end

      # `action` is :buy or :sell
      def trade action
      end

      # `action` is :buy or :sell
      # Returns a Numeric type.
      def price action
      end

      # Transfers BTC to the address of a different
      # exchange.
      def transfer client
      end

      # If there is an API method to fetch your
      # BTC address, implement this, otherwise
      # remove this method and set the ENV
      # variable [this-exchange-name-in-caps]_ADDRESS
      def address
      end
    end
  end
end
