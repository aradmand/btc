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
      require 'active_support/core_ext/object/try'

      # return a symbol as the name
      # of this exchange
      def exchange
        :coinbase_exchange
      end

      def exchange_fee
        0.0025
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
        coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new
        coinbase_client.validate_env

        validate_keys :coinbase_exchange_access_key,
          :coinbase_exchange_api_secret,
          :coinbase_exchange_passphrase
      end

      # `action` is :buy or :sell
      def trade(action, override_values = nil)
        price = price(action)
        multiple = {
          buy: 1,
          sell: -1,
        }[action]
        adjusted_price = price + 0.01 * multiple
        adjusted_price = adjusted_price.round(2)

        amount = override_values.try(:[], :volume) || @options[:volume]

        side = if action == :buy
          'buy'
        else
          'sell'
        end
        result = place_new_order_command(amount, adjusted_price, side)
      end

      # `action` is :buy or :sell
      # Returns a Numeric type.
      def price action
        bids_asks_hash = order_book_command(action)

        if action == :buy
          #buy = asks
          price_entries = bids_asks_hash[:asks]
          price_entries.second.first.try(:to_f)
        else
          #sell = bids
          price_entries = bids_asks_hash[:bids]
          price_entries.first.first.try(:to_f)
        end
      end

      # Transfers BTC to the address of a different
      # exchange.
      def transfer(client, override_values = nil)
        # With CoinbaseExchange, this is a 2-step process:
        # 1.) Transfer BTC from CoinbaseExchange BTC account to
        # Bitcoin.com's BTC Wallet
        #
        # 2.) Transfer BTC from the BTC Wallet account to the specified
        # client address.

        # First, transfer BTC from CoinbaseExchange BTC acct to Bitcoin Wallet
        volume = override_values.try(:[], :volume) || @options[:volume]

        coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new(self.options.merge({volume: volume}))
        coinbase_account = coinbase_client.account('My Wallet')

        transfer_response = transfer_funds_command('withdraw', volume, coinbase_account['id'])

        # Second, transfer BTC from Coinbase BTC Wallet to the desired client
        coinbase_transfer_response = coinbase_client.transfer(client)
      end

      # If there is an API method to fetch your
      # BTC address, implement this, otherwise
      # remove this method and set the ENV
      # variable [this-exchange-name-in-caps]_ADDRESS
      def address(transfer_to_exchange = false)
        # First get the address of the coinbase wallet
        coinbase_client = RbtcArbitrage::Clients::CoinbaseClient.new
        coinbase_client_address = coinbase_client.address

        # Second, initiate a transfer from Coinbase to CoinbaseExchange
        if coinbase_client_address.present? && transfer_to_exchange
          coinbase_account = coinbase_client.account('My Wallet')
          transfer_response = transfer_funds_command('deposit', @options[:volume], coinbase_account['id'])
        end

        coinbase_client_address
      end

      def open_orders
        orders_command
      end

      private

      def exchange_api_url
        'https://api.exchange.coinbase.com'
      end

      # transfer_type = 'deposit' or 'withdraw'
      # amount = the amount to either deposit or withdraw (10.32)
      # account_id = coinbase account id
      #
      # For Reference:
      # ‘Withdraw’ = Exchange → Coinbase
      # ‘Deposit’ = Coinbase → Exchange
      def transfer_funds_command(transfer_type, amount, account_id)
        request_body = {
          "type" => transfer_type,
          "amount" => amount,
          "coinbase_account_id" => account_id
        }

        auth_headers = signature('/transfers', request_body, nil, 'POST')

        api_url = "#{exchange_api_url}/transfers"
        path_header = "/transfers"

        curl = Curl::Easy.new
        headers = {}
        headers['host'] = 'api.exchange.coinbase.com'
        headers['method'] = 'POST'
        headers['path'] = path_header
        headers['scheme'] = 'https'
        headers['version'] = 'HTTP/1.1'
        headers['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
        headers['accept-encoding'] = 'gzip,deflate,sdch'
        headers['accept-language'] = 'en-US,en;q=0.8'
        headers['content-type'] = 'application/json'
        headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"
        headers["CB-ACCESS-PASSPHRASE"] = auth_headers[:cb_access_passphrase]
        headers["CB-ACCESS-TIMESTAMP"] = auth_headers[:cb_access_timestamp]
        headers["CB-ACCESS-KEY"] = auth_headers[:cb_access_key]
        headers["CB-ACCESS-SIGN"] = auth_headers[:cb_access_sign]

        curl.url = api_url
        curl.headers = headers
        curl.verbose = true

        curl.http_post(request_body.to_json)

        begin
          json_data = ActiveSupport::Gzip.decompress(curl.body_str)
          parsed_json = JSON.parse(json_data)
          id = parsed_json['id']
          ledger_id = parsed_json['ledger_id']
          if id.blank? || ledger_id.blank?
            puts 'Error within transfer_funds_command. Response:'
            puts json_data
          end

          {'id' => id, 'ledger_id' => ledger_id}
        rescue
          puts "Error while reading response in transfer_funds_command:"
          puts curl.body_str
          return nil
        end
      end

      def place_new_order_command(size, price, side)
        product_id = products_command['id']

        request_body = {
          "size" => size,
          "price" => price,
          "side" => side,
          "product_id" => product_id
        }

        auth_headers = signature('/orders', request_body, nil, 'POST')

        api_url = "#{exchange_api_url}/orders"

        path_header = "/orders"

        curl = Curl::Easy.new
        headers = {}
        headers['host'] = 'api.exchange.coinbase.com'
        headers['method'] = 'POST'
        headers['path'] = path_header
        headers['scheme'] = 'https'
        headers['version'] = 'HTTP/1.1'
        headers['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
        headers['accept-encoding'] = 'gzip,deflate,sdch'
        headers['accept-language'] = 'en-US,en;q=0.8'
        headers['content-type'] = 'application/json'
        headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"
        headers["CB-ACCESS-PASSPHRASE"] = auth_headers[:cb_access_passphrase]
        headers["CB-ACCESS-TIMESTAMP"] = auth_headers[:cb_access_timestamp]
        headers["CB-ACCESS-KEY"] = auth_headers[:cb_access_key]
        headers["CB-ACCESS-SIGN"] = auth_headers[:cb_access_sign]

        curl.url = api_url
        curl.headers = headers
        curl.verbose = true

        curl.http_post(request_body.to_json)

        begin
          json_data = ActiveSupport::Gzip.decompress(curl.body_str)
          parsed_json = JSON.parse(json_data)
          order_id = parsed_json['id']
          puts 'Order Id:'
          puts order_id
          puts 'Order Details:'
          puts parsed_json
          return order_id
        rescue
          puts "Error while reading response:"
          puts curl.body_str
          return nil
        end
      end

      def orders_command
        auth_headers = signature('/orders', '', nil, 'GET')

        api_url = "#{exchange_api_url}/orders"

        path_header = "/orders"

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

        if curl.body_str.length < 5
          parsed_json = JSON.parse(curl.body_str)
        else
          json_data = ActiveSupport::Gzip.decompress(curl.body_str)
          parsed_json = JSON.parse(json_data)
        end
      end

      def accounts_command
        auth_headers = signature('/accounts', '', nil, 'GET')

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
      # body is the JSON body
      def signature(request_url='', body='', timestamp=nil, method='GET')
        api_secret = ENV['COINBASE_EXCHANGE_API_SECRET']

        body = body.to_json if body.is_a?(Hash)
        timestamp = Time.now.to_i if !timestamp

        what = "#{timestamp}#{method}#{request_url}#{body}";

        # create a sha256 hmac with the secret
        secret = Base64.decode64(api_secret)
        hash  = OpenSSL::HMAC.digest('sha256', secret, what)
        cb_access_sign = Base64.encode64(hash)

        {
          cb_access_timestamp: timestamp,
          cb_access_key: ENV['COINBASE_EXCHANGE_ACCESS_KEY'],
          cb_access_sign: cb_access_sign.strip,
          cb_access_passphrase: ENV['COINBASE_EXCHANGE_PASSPHRASE']
        }
      end

      def order_book_command(action)
        product_id = products_command['id']
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

        {
          bids: parsed_json['bids'],
          asks: parsed_json['asks']
        }
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

        btc_usd_product = parsed_json.map do |product|
          if product['id'] == 'BTC-USD'
            product
          end
        end.first
      end
    end
  end
end
