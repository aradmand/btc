module RbtcArbitrage
  module Clients
    class CircleClient
      include RbtcArbitrage::Client

      require 'pry'
      require 'curb'
      require 'active_support'
      require 'json'

      # return a symbol as the name
      # of this exchange
      def exchange
        :circle
      end

      # Returns an array of Floats.
      # The first element is the balance in BTC;
      # The second is in USD.
      def balance
        return @balance if @balance.present?

        result = api_customers_command

        @balance = [ result[:account_balance_in_btc_normalized], result[:account_balance_in_usd] ]
      end

      def interface
      end

      # Configures the client's API keys.
      #
      # circle_customer_id is the user's customer id (ie 168900 in the api call "www.circle.com/api/v2/customers/168900/accounts/186074/deposits")
      #
      # circle_bank_account_id is the user's bank account that is to be used (ie 186074 in the api call "www.circle.com/api/v2/customers/168900/accounts/186074/deposits")
      def validate_env
        validate_keys :circle_customer_session_token, :circle_cookie, :circle_customer_id, :circle_bank_account_id
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

    private

      def api_customers_command(customer_id = ENV['CIRCLE_CUSTOMER_ID'], customer_session_token = ENV['CIRCLE_CUSTOMER_SESSION_TOKEN'])
        api_url = "https://www.circle.com/api/v2/customers/#{customer_id}"

        path_header = "/api/v2/customers/#{customer_id}"

        curl = Curl::Easy.new(api_url) do |http|
          http.headers['host'] = 'www.circle.com'
          http.headers['method'] = 'GET'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'application/json, text/plain, */*'
          http.headers['accept-encoding'] = 'gzip,deflate,sdch'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['cookie'] = circle_cookie
          http.headers['referer'] = "https://www.circle.com/accounts"
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
          http.headers['x-customer-id'] = customer_id
          http.headers['x-customer-session-token'] = customer_session_token
        end

        response = curl.perform

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)
        exchange_rate_object = parsed_json['response']['customer']['exchangeRate']
        exchange_rate = parsed_json['response']['customer']['exchangeRate']['USD']['rate']
        account_balance_in_btc_raw = parsed_json['response']['customer']['accounts'].first['satoshiAvailableBalance']
        account_balance_in_btc_normalized = account_balance_in_btc_raw / 100000000.0
        account_balance_in_usd = exchange_rate * account_balance_in_btc_normalized

        {
          exchange_rate_object: exchange_rate_object,
          exchange_rate: exchange_rate,
          account_balance_in_btc_raw: account_balance_in_btc_raw,
          account_balance_in_btc_normalized: account_balance_in_btc_normalized,
          account_balance_in_usd: account_balance_in_usd
        }
      end
    end
  end
end
