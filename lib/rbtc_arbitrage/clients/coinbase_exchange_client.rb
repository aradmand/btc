module RbtcArbitrage
  module Clients
    class CoinbaseExchangeClient
      include RbtcArbitrage::Client

      require 'pry'
      require 'curb'
      require 'active_support'
      require 'json'
      require 'base64'
      require 'openssl'

      # return a symbol as the name
      # of this exchange
      def exchange
        :coinbase_exchange
      end

      # Returns an array of Floats.
      # The first element is the balance in BTC;
      # The second is in USD.
      def balance
        balances = accounts_command
        [balances[:btc_balance], balances[:usd_balance]]
      end

      def interface
      end

      # Configures the client's API keys.
      def validate_env
        validate_keys :coinbase_exchange_access_key, :coinbase_exchange_api_secret, :coinbase_exchange_passphrase, :coinbase_exchange_address
      end

      # `action` is :buy or :sell
      def trade action
      end

      # `action` is :buy or :sell
      # Returns a Numeric type.
      def price action
        order_book_command(action)
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
        #This is best left as an environment variable.
      end

      private

      def exchange_api_url
        'https://api.exchange.coinbase.com'
      end

      def accounts_command
        auth_headers = authentication_headers('GET', '/accounts')

        api_url = "#{exchange_api_url}/accounts"

        path_header = "/accounts"

        curl = Curl::Easy.new(api_url) do |http|
          http.headers['host'] = 'api.exchange.coinbase.com'
          http.headers['method'] = 'GET'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
          http.headers['accept-encoding'] = 'gzip,deflate,sdch'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['content-type'] = 'application/json;charset=UTF-8'
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"
          http.headers["CB-ACCESS-PASSPHRASE"] = auth_headers[:cb_access_passphrase]
          http.headers["CB-ACCESS-TIMESTAMP"] = auth_headers[:cb_access_timestamp]
          http.headers["CB-ACCESS-KEY"] = auth_headers[:cb_access_key]
          http.headers["CB-ACCESS-SIGN"] = auth_headers[:cb_access_sign]
        end

        response = curl.perform

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        usd_balance = 0
        btc_balance = 0
        parsed_json.each do |account|
          if account['currency'] == 'BTC'
            btc_balance = account['available'].try(:to_f)
          elsif account['currency'] == 'USD'
            usd_balance = account['available'].try(:to_f)
          end
        end

        {
          btc_balance: btc_balance,
          usd_balance: usd_balance
        }
      end

      # method must be CAPITALIZED and should be POST, GET ... etc
      # request_url should be the url called (i.e. '/orders', '/account' ... etc)
      # body is the JSON body converted to a string
      def authentication_headers(method, request_url, body = "")
        api_secret = ENV['COINBASE_EXCHANGE_API_SECRET']
        timestamp = Time.now.to_i

        # create prehash string
        prehash_string = timestamp.to_s + method + request_url + body

        # decode base64 secret
        decoded_api_secret = Base64.decode64(api_secret)

        # create a sha256 hmac with the secret
        digest = OpenSSL::Digest::Digest.new("sha256")
        hmac = OpenSSL::HMAC.digest(digest, decoded_api_secret, prehash_string)

        # base64 encode the result
        cb_access_sign = Base64.encode64(hmac)

        {
          cb_access_timestamp: timestamp,
          cb_access_key: ENV['COINBASE_EXCHANGE_ACCESS_KEY'],
          cb_access_sign: cb_access_sign,
          cb_access_passphrase: ENV['COINBASE_EXCHANGE_PASSPHRASE']
        }
      end

      def order_book_command(action)
        product_id = products_command
        api_url = "#{exchange_api_url}/products/#{product_id}/book?level=2"

        path_header = "/products/#{product_id}/book?level=2"

        curl = Curl::Easy.new(api_url) do |http|
          http.headers['host'] = 'api.exchange.coinbase.com'
          http.headers['method'] = 'GET'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
          http.headers['accept-encoding'] = 'gzip,deflate,sdch'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"
        end

        response = curl.perform

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        if action == :buy
          #buy = asks
          price_entry = parsed_json['asks'].third
          price_entry.first.try(:to_f)
        else
          #sell = bids
          price_entry = parsed_json['bids'].third
          price_entry.first.try(:to_f)
        end
      end

      def products_command
        api_url = "#{exchange_api_url}/products"
        path_header = '/products'

        curl = Curl::Easy.new(api_url) do |http|
          http.headers['host'] = 'api.exchange.coinbase.com'
          http.headers['method'] = 'GET'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
          http.headers['accept-encoding'] = 'gzip,deflate,sdch'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"
        end

        response = curl.perform

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        product_id = parsed_json.map do |product|
          if product['id'] == 'BTC-USD'
            product['id']
          end
        end.first
      end
    end
  end
end
