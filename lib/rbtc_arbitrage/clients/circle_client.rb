module RbtcArbitrage
  module Clients
    class CircleClient
      include RbtcArbitrage::Client

      require 'pry'
      require 'curb'
      require 'active_support'
      require 'json'
      require 'active_support/core_ext/object/try'

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
        if action == :buy
          buy_btc(@options[:volume])
        else
          sell_btc(@options[:volume])
        end
      end

      # `action` is :buy or :sell
      # Returns a Numeric type.
      def price action
        result = api_customers_command
        exchange_rate = result[:exchange_rate]
        exchange_rate.to_f
      end

      # Transfers BTC to the address of a different
      # exchange.
      #
      # NOTE: The volume of BTC exchanged MUST be 0.01 BTC or
      #  Higher, or this transfer method will NOT work.
      #  As a result, the default volume to exchange has been changed
      #  to 0.011 BTC
      def transfer(other_client, override_values = nil)
        if other_client.exchange == :coinbase_exchange
          client_address = other_client.address(true)
          volume = override_values.try(:[], :volume) || @options[:volume]
          transfer_btc(volume, other_client)
        else
          volume = override_values.try(:[], :volume) || @options[:volume]
          transfer_btc(volume, other_client)
        end
      end

      # If there is an API method to fetch your
      # BTC address, implement this, otherwise
      # remove this method and set the ENV
      # variable [this-exchange-name-in-caps]_ADDRESS
      def address
        api_address_command
      end

      def open_orders
        []
      end

    private

      def api_address_command(customer_id = ENV['CIRCLE_CUSTOMER_ID'], customer_session_token = ENV['CIRCLE_CUSTOMER_SESSION_TOKEN'], circle_bank_account_id = ENV['CIRCLE_BANK_ACCOUNT_ID'])
        api_url = "https://www.circle.com/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/address"

        path_header = "/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/address"

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
          http.headers['referer'] = "https://www.circle.com/request"
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
          http.headers['x-customer-id'] = customer_id
          http.headers['x-customer-session-token'] = circle_customer_session_token
        end

        response = curl.perform
        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        circle_bitcoin_address_for_receiving = parsed_json['response']['bitcoinAddress']
      end

      def fiat_account_command(customer_id = ENV['CIRCLE_CUSTOMER_ID'], customer_session_token = ENV['CIRCLE_CUSTOMER_SESSION_TOKEN'])
        api_url = "https://www.circle.com/api/v2/customers/#{customer_id}/fiatAccounts"

        path_header = "/api/v2/customers/#{customer_id}/fiatAccounts"

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
          http.headers['referer'] = "https://www.circle.com/deposit"
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
          http.headers['x-customer-id'] = customer_id
          http.headers['x-customer-session-token'] = circle_customer_session_token
        end

        response = curl.perform

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)
        fiat_account_array = parsed_json['response']['fiatAccounts']

        fiat_account_id = find_fiat_account_id(fiat_account_array)

        {
          fiat_account_id: fiat_account_id,
          fiat_account_array: fiat_account_array
        }
      end

      def find_fiat_account_id(fiat_account_array)
        fiat_account_id = nil
        fiat_account_array.each do |fiat_account|
          if fiat_account['accountType'] == 'checking' && fiat_account['description'] == fiat_account_description
            fiat_account_id = fiat_account['id']
            break
          end
        end

        if fiat_account_id.blank?
          puts 'ERROR LOCATING FIAT ACCOUNT ID!'
          exit
        end
        fiat_account_id
      end

      def buy_btc(volume)
        fiat_account_command_result = fiat_account_command
        fiat_account_id = fiat_account_command_result[:fiat_account_id]

        customers_command_result = api_customers_command

        exchange_rate_object = customers_command_result[:exchange_rate_object]
        exchange_rate_object_for_deposit_request = exchange_rate_object["USD"]
        exchange_rate = customers_command_result[:exchange_rate]
        fiat_value = calculate_fiat_value_for_exchange_rate(exchange_rate, volume)

        deposit_json_data = {"deposit" =>
          {"fiatAccountId" => fiat_account_id,
            "fiatValue" => fiat_value,
            "exchangeRate" => exchange_rate_object_for_deposit_request
          }
        }

        api_deposit_command_result = api_deposits_command(deposit_json_data)
      end

      def sell_btc(volume)
        fiat_account_command_result = fiat_account_command
        fiat_account_id = fiat_account_command_result[:fiat_account_id]

        customers_command_result = api_customers_command

        exchange_rate_object = customers_command_result[:exchange_rate_object]
        exchange_rate_object_for_deposit_request = exchange_rate_object["USD"]
        exchange_rate = customers_command_result[:exchange_rate]
        fiat_value = calculate_fiat_value_for_exchange_rate(exchange_rate, volume)

        withdraw_json_data = {"withdraw" =>
          {"fiatAccountId" => fiat_account_id,
            "fiatValue" => fiat_value,
            "exchangeRate" => exchange_rate_object_for_deposit_request
          }
        }

        api_withdraws_command_result = api_withdraws_command(withdraw_json_data)
      end

      def api_withdraws_command(withdraw_json_data, customer_id = ENV['CIRCLE_CUSTOMER_ID'], customer_session_token = ENV['CIRCLE_CUSTOMER_SESSION_TOKEN'], circle_bank_account_id = ENV['CIRCLE_BANK_ACCOUNT_ID'])
        api_url = "https://www.circle.com/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/withdraws"

        path_header = "/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/withdraws"

        withdraw_json_data = withdraw_json_data.to_json
        content_length = withdraw_json_data.length

        curl = Curl::Easy.http_post(api_url, withdraw_json_data) do |http|
          http.headers['host'] = 'www.circle.com'
          http.headers['method'] = 'POST'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'application/json, text/plain, */*'
          http.headers['accept-encoding'] = 'gzip,deflate'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['content-length'] = content_length
          http.headers['content-type'] = 'application/json;charset=UTF-8'
          http.headers['cookie'] = circle_cookie
          http.headers['origin'] = 'https://www.circle.com'
          http.headers['referer'] = "https://www.circle.com/withdraw/confirm"
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
          http.headers['x-customer-id'] = customer_id
          http.headers['x-customer-session-token'] = circle_customer_session_token
        end

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        withdraw_response_status = parsed_json
        response_code = withdraw_response_status['response']['status']['code']
        if response_code == 0
          # puts 'Successful Withdraw!'
          # puts 'Withdraw Details:'
          # puts withdraw_response_status
        else
          puts '** ERROR ** Withdraw Unsuccessful'
          puts 'Withdraw Details:'
          puts withdraw_response_status
        end

        satoshi_value_withdrawn = withdraw_response_status['response']['transaction']['satoshiValue']
        {status: response_code, satoshi_value: satoshi_value_withdrawn}
      end

      def api_deposits_command(deposit_json_data, customer_id = ENV['CIRCLE_CUSTOMER_ID'], customer_session_token = ENV['CIRCLE_CUSTOMER_SESSION_TOKEN'], circle_bank_account_id = ENV['CIRCLE_BANK_ACCOUNT_ID'])
        api_url = "https://www.circle.com/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/deposits"

        path_header = "/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/deposits"

        deposit_json_data = deposit_json_data.to_json
        content_length = deposit_json_data.length

        curl = Curl::Easy.http_post(api_url, deposit_json_data) do |http|
          http.headers['host'] = 'www.circle.com'
          http.headers['method'] = 'POST'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'application/json, text/plain, */*'
          http.headers['accept-encoding'] = 'gzip,deflate'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['content-length'] = content_length
          http.headers['content-type'] = 'application/json;charset=UTF-8'
          http.headers['cookie'] = circle_cookie
          http.headers['origin'] = 'https://www.circle.com'
          http.headers['referer'] = "https://www.circle.com/deposit"
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
          http.headers['x-customer-id'] = customer_id
          http.headers['x-customer-session-token'] = circle_customer_session_token
        end

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        deposit_response_status = parsed_json
        response_code = deposit_response_status['response']['status']['code']
        if response_code == 0
          # puts 'Successful Deposit!'
          # puts 'Deposit Details:'
          # puts deposit_response_status
        else
          puts '** ERROR ** Deposit Unsuccessful'
          puts 'Deposit Details:'
          puts deposit_response_status
        end

        satoshi_value_deposited = deposit_response_status['response']['transaction']['satoshiValue']
        {status: response_code, satoshi_value: satoshi_value_deposited}
      end

      def calculate_satoshi_value(fiat_value, exchange_rate)
        # A Satoshi is the smallest denomination of BTC
        # 1 Satoshi = 0.00000001 BTC

        satoshi_value = (fiat_value / exchange_rate.to_f).round(18)
        saftey_index = 0

        while satoshi_value.to_s.first == '0'
          satoshi_value = satoshi_value * 10

          saftey_index += 1
          if saftey_index >= 18
            raise 'Error while trying to calculate satoshi value!'
            exit
          end
        end
        satoshi_value * 1000000
      end

      # btc_to_dollar_exchange_rate is the rate to exchange one bitcoin into dollars,
      # so if the exchange rate is 1 Btc = 376.78, then btc_to_dollar_exchange_rate
      # should be 376.78
      def calculate_fiat_value_for_exchange_rate(btc_to_dollar_exchange_rate, amount_of_btc_to_purchase = 0.01)
        (amount_of_btc_to_purchase * btc_to_dollar_exchange_rate).round(2)
      end

      def transfer_btc(volume_in_btc, other_client)
        other_client_btc_address = other_client.address
        volume = volume_in_btc

        customers_command_result = api_customers_command

        exchange_rate_object = customers_command_result[:exchange_rate_object]
        exchange_rate = customers_command_result[:exchange_rate]
        fiat_value = calculate_fiat_value_for_exchange_rate(exchange_rate, volume)

        satoshi_value = calculate_satoshi_value(fiat_value, exchange_rate)

        exchange_rate_object_for_btc_transfer = exchange_rate_object["USD"]

        btc_transfer_json_data = {"transaction" =>
          {"exchangeRate" => exchange_rate_object_for_btc_transfer,
          "bitcoinOrEmailAddress" => other_client_btc_address,
          "satoshiValue" => satoshi_value,
          "fiatValue" => fiat_value,
          "currencyCode" => "USD",
          "message" => "sending #{volume} btc (#{fiat_value}) to #{other_client.exchange.to_s}."
          }
        }

        response = api_transactions_command(btc_transfer_json_data)
      end

      ## Circle Uses the transactions command internally to do btc transfers
      def api_transactions_command(transfer_json_data, customer_id = ENV['CIRCLE_CUSTOMER_ID'], customer_session_token = ENV['CIRCLE_CUSTOMER_SESSION_TOKEN'], circle_bank_account_id = ENV['CIRCLE_BANK_ACCOUNT_ID'])
        btc_transfer_json_data = transfer_json_data.to_json
        content_length = btc_transfer_json_data.length

        api_url = "https://www.circle.com/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/transactions"

        path_header = "/api/v2/customers/#{customer_id}/accounts/#{circle_bank_account_id}/transactions"

        curl = Curl::Easy.http_post(api_url, btc_transfer_json_data) do |http|
          http.headers['host'] = 'www.circle.com'
          http.headers['method'] = 'POST'
          http.headers['path'] = path_header
          http.headers['scheme'] = 'https'
          http.headers['version'] = 'HTTP/1.1'
          http.headers['accept'] = 'application/json, text/plain, */*'
          http.headers['accept-encoding'] = 'gzip,deflate'
          http.headers['accept-language'] = 'en-US,en;q=0.8'
          http.headers['content-length'] = content_length
          http.headers['content-type'] = 'application/json;charset=UTF-8'
          http.headers['cookie'] = circle_cookie
          http.headers['origin'] = 'https://www.circle.com'
          http.headers['referer'] = "https://www.circle.com/send/confirm"
          http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
          http.headers['x-app-id'] = 'angularjs'
          http.headers['x-app-version'] = "0.0.1"
          http.headers['x-customer-id'] = customer_id
          http.headers['x-customer-session-token'] = customer_session_token
        end

        json_data = ActiveSupport::Gzip.decompress(curl.body_str)
        parsed_json = JSON.parse(json_data)

        btc_transfer_response_status = parsed_json
        response_code = btc_transfer_response_status['response']['status']['code']
        if response_code == 0
          # puts 'Successful BTC tansfer!'
          # puts 'Transfer Details:'
          # puts btc_transfer_response_status
        else
          puts '** ERROR ** BTC Transfer Unsuccessful'
          puts 'Transfer Details:'
          puts btc_transfer_response_status
        end
        response_code
      end

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

      ###
      #  This should be set to the description of the Checking
      #  account you are interested in using for deposits / withdraws
      #  for buying and selling BTC.
      ###
      def fiat_account_description
        "BANK OF AMERICA, N.A. ****4655"
      end

      def circle_cookie
        ENV['CIRCLE_COOKIE']
      end

      def circle_customer_session_token
        ENV['CIRCLE_CUSTOMER_SESSION_TOKEN']
      end
    end
  end
end
