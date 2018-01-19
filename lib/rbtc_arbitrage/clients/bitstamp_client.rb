module RbtcArbitrage
  module Clients
    class BitstampClient
      include RbtcArbitrage::Client

      def balance
        balances = account_balance_command

        #btc balance first, then usd balance
        [balances[:btc_balance].to_f, balances[:usd_balance].to_f]
      end

      def validate_env
        validate_keys :bitstamp_key, :bitstamp_client_id, :bitstamp_secret
        Bitstamp.setup do |config|
          config.client_id = ENV["BITSTAMP_CLIENT_ID"]
          config.key = ENV["BITSTAMP_KEY"]
          config.secret = ENV["BITSTAMP_SECRET"]
        end
      end

      def exchange
        :bitstamp
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
        price(action) unless @price #memoize
        multiple = {
          buy: 1,
          sell: -1,
        }[action]
        bitstamp_options = {
          price: (@price + 0.001 * multiple),
          amount: @options[:volume],
        }
        Bitstamp.orders.send(action, bitstamp_options)
      end

      def transfer other_client
        Bitstamp.transfer(@options[:volume], other_client.address)
      end

      def exchange_api_url
        "https://www.bitstamp.net/api/v2"
      end

      def order_book_command
        api_url = "#{exchange_api_url}/order_book/btcusd/"
        path_header = "order_book/btcusd"
        json_data = nil
        parsed_json = nil
        curl = nil

        curl = Curl::Easy.new(api_url) do |http|
          http.headers['host'] = 'www.bitstamp.net'
          http.headers['method'] = 'GET'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
          http.headers['accept-encoding'] = 'gzip,deflate,sdch'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['content-type'] = 'application/json;charset=UTF-8'
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

      def signature
        api_secret = ENV['BITSTAMP_SECRET']
        api_key = ENV['BITSTAMP_KEY']
        client_id = ENV['BITSTAMP_CLIENT_ID']

        timestamp = Time.now.to_i if !timestamp

        message = "#{timestamp}#{client_id}#{api_key}"

        # create a sha256 hmac with the secret
        signature = HMAC::SHA256.hexdigest(api_secret, message).upcase

        data = {
          nonce: timestamp,
          key: api_key,
          signature: signature
        }
        data = data.map { |k,v| "#{k}=#{v}"}.join('&')
      end

      def account_balance_command
        auth_params = signature

        api_url = "#{exchange_api_url}/balance/btcusd/?#{auth_params}"

        path_header = "/balance/btcusd"

        parsed_json = nil

        url = URI.parse("#{exchange_api_url}/balance/btcusd/")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        headers = {
          'Content-Type' => 'application/x-www-form-urlencoded'
        }

        resp = http.post(url.path, auth_params, headers)

        parsed_json = JSON.parse(resp.body)

        usd_balance = parsed_json['usd_available']
        btc_balance = parsed_json['btc_available']

        {
          btc_balance: btc_balance,
          usd_balance: usd_balance
        }
      end
    end
  end
end
