module RbtcArbitrage

  require 'httparty'
  require 'base64'
  require 'addressable/uri'

  module Clients
    class KrakenClient
      include RbtcArbitrage::Client
      include HTTParty

      def balance
        balances = account_balance_command

        #btc balance first, then usd balance
        [balances[:btc_balance].to_f, balances[:usd_balance].to_f]
      end

      def validate_env
        validate_keys :kraken_key, :kraken_secret
      end

      def exchange
        :kraken
      end

      def price action
        bids_asks_hash = order_book_command

        if action == :buy
          #buy = asks
          price_entries = bids_asks_hash[:asks]
          price_entries.fourth.first.try(:to_f)
        else
          #sell = bids
          price_entries = bids_asks_hash[:bids]
          price_entries.first.first.try(:to_f)
        end
      end

      def trade action
        price = price(action)
        multiple = {
          buy: 1,
          sell: -1,
        }[action]

        adjusted_price = price + 0.01 * multiple
        adjusted_price = adjusted_price.round(2)

        side = action == :buy ? 'buy' : 'sell'
        result = add_order(side, @options[:volume], adjusted_price)
      end

      def transfer other_client
        #Bitstamp.transfer(@options[:volume], other_client.address)
      end

      def exchange_api_url
        "https://api.kraken.com/0"
      end

      def order_book_command
        api_url = "#{exchange_api_url}/public/Depth?pair=XBTUSD"
        path_header = "public/Depth"
        json_data = nil
        parsed_json = nil
        curl = nil

        url = URI.parse(api_url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        resp = http.get(api_url)
        result = JSON.parse(resp.body)

        {
          bids: result["result"]["XXBTZUSD"]["bids"],
          asks: result["result"]["XXBTZUSD"]["asks"]
        }
      end

      def add_order(side, volume, price)
        opts = {
          pair: 'XBTUSD',
          type: side,
          ordertype: 'limit',
          volume: volume,
          price: price
        }

        result = post_private 'AddOrder', opts
      end

      def open_orders
        results = post_private 'OpenOrders', {}
        results['open'].to_a
      end

      def account_balance_command
        results = post_private 'Balance', {}

        usd_balance = results['ZUSD'] || 0
        btc_balance = results['XXBT'] || 0

        {
          btc_balance: btc_balance,
          usd_balance: usd_balance
        }
      end

       def address
        return @bitcoin_address if @bitcoin_address

        result = post_private 'DepositAddresses', {'asset' => 'XBT', 'method' => 'Bitcoin'}
        @bitcoin_address = result.first['address']
      end

      private

      attr_reader :bitcoin_address

      def post_private(method, opts={})
        opts['nonce'] = nonce
        post_data = encode_options(opts)

        headers = {
          'API-Key' => ENV['KRAKEN_KEY'],
          'API-Sign' => generate_signature(method, post_data, opts)
        }

        url = 'https://api.kraken.com' + url_path(method)
        r = self.class.post(url, { headers: headers, body: post_data }).parsed_response
        r['error'].empty? ? r['result'] : r['error']
      end

      def nonce
        nonce = Time.now.to_i
        nonce.to_s
      end

      def encode_options(opts)
        uri = Addressable::URI.new
        uri.query_values = opts
        uri.query
      end

      def generate_signature(method, post_data, opts={})
        api_secret = ENV['KRAKEN_SECRET']
        key = Base64.decode64(api_secret)
        message = generate_message(method, opts, post_data)
        generate_hmac(key, message)
      end

      def generate_message(method, opts, data)
        digest = OpenSSL::Digest.new('sha256', opts['nonce'] + data).digest
        url_path(method) + digest
      end

      def generate_hmac(key, message)
        Base64.strict_encode64(OpenSSL::HMAC.digest('sha512', key, message))
      end

      def url_path(method)
        '/' + '0' + '/private/' + method
      end
    end
  end
end
