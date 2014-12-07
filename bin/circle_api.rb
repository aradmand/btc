require 'pry'
require 'curb'
require 'active_support'
require 'json'

#Investigations into the Circle API
#export CIRCLE_CUSTOMER_SESSION_TOKEN=

def circle_customer_session_token
  ENV['CIRCLE_CUSTOMER_SESSION_TOKEN']
end

def circle_cookie
  "__cfduid=deddacfaa1ccc0a87f2dbb02236992f141415920996; _ys_trusted=%7B%22_%22%3A%227f9d364d1b7072f2624f1d38d4f16f331524bd0a%22%7D; optimizelyEndUserId=oeu1415922855321r0.6195648575667292; _ga=GA1.2.487562618.1415920999; optimizelySegments=%7B%7D; optimizelyBuckets=%7B%222169471078%22%3A%222162540652%22%7D; __zlcmid=RveDshCuVRISei; _ys_session=%7B%22_%22%3A%7B%22value%22%3A%229ec0a4d0fe0bf629b772e18f0fefcfef7832e53a%22%2C%22customerId%22%3A168900%2C%22expiryDate%22%3A1417609392035%7D%7D; AWSELB=6DE1C52F06D2FAD97948D9C525A94E7AAFA0177A1849DCA38BC685C7E31BBBD7E67C9F116A7A080C3C55A596F5F12AF54EFBD28ACBD89C30D991105D4265F1C4645BF26719; i18next=en; _ys_state=%7B%22_%22%3A%7B%22isEmailVerified%22%3Atrue%2C%22isMfaVerified%22%3Atrue%7D%7D; __utma=100973971.487562618.1415920999.1417477888.1417608165.9; __utmb=100973971.8.9.1417608278937; __utmc=100973971; __utmz=100973971.1415920999.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)"
end

def coinbase_btc_address
  "16xXNkdeH71irdeKbgWxsZT63PHBPXps3t"
end

# btc_to_dollar_exchange_rate is the rate to exchange one bitcoin into dollars,
# so if the exchange rate is 1 Btc = 376.78, then btc_to_dollar_exchange_rate
# should be 376.78
def calculate_fiat_value_for_exchange_rate(btc_to_dollar_exchange_rate, amount_of_btc_to_purchase = 0.11)
  (amount_of_btc_to_purchase * btc_to_dollar_exchange_rate).round(2)
end

################################################################################
# Generate bitcoin Address for receiving bitcoin
################################################################################


curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/168900/accounts/186074/address") do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'GET'
  http.headers['path'] = '/api/v2/customers/168900/accounts/186074/address'
  http.headers['scheme'] = 'https'
  http.headers['version'] = 'HTTP/1.1'
  http.headers['accept'] = 'application/json, text/plain, */*'
  http.headers['accept-encoding'] = 'gzip,deflate,sdch'
  http.headers['accept-language'] = 'en-US,en;q=0.8'
  http.headers['cookie'] = circle_cookie
  http.headers['referer'] = "https://www.circle.com/request"
  http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
  http.headers['x-customer-id'] = "168900"
  http.headers['x-customer-session-token'] = circle_customer_session_token
end

response = curl.perform
json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)

circle_bitcoin_address_for_receiving = parsed_json['response']['bitcoinAddress']


################################################################################
# Obtain fiatAccount information
################################################################################

curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/168900/fiatAccounts") do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'GET'
  http.headers['path'] = '/api/v2/customers/168900/fiatAccounts'
  http.headers['scheme'] = 'https'
  http.headers['version'] = 'HTTP/1.1'
  http.headers['accept'] = 'application/json, text/plain, */*'
  http.headers['accept-encoding'] = 'gzip,deflate,sdch'
  http.headers['accept-language'] = 'en-US,en;q=0.8'
  http.headers['cookie'] = circle_cookie
  http.headers['referer'] = "https://www.circle.com/deposit"
  http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
  http.headers['x-customer-id'] = "168900"
  http.headers['x-customer-session-token'] = circle_customer_session_token
end

response = curl.perform

json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)
fiat_account_array = parsed_json['response']['fiatAccounts']




# Set fiat_account_id
fiat_account_id = nil
fiat_account_array.each do |fiat_account|
  if fiat_account['accountType'] == 'checking' && fiat_account['description'] == "BANK OF AMERICA, N.A. ****4655"
    fiat_account_id = fiat_account['id']
    break
  end
end

if fiat_account_id.empty?
  puts 'ERROR LOCATING FIAT ACCOUNT ID!'
  exit
end


################################################################################
# Obtain exchange rate, account balance in btc and account balance in usd
################################################################################


curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/168900") do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'GET'
  http.headers['path'] = '/api/v2/customers/168900'
  http.headers['scheme'] = 'https'
  http.headers['version'] = 'HTTP/1.1'
  http.headers['accept'] = 'application/json, text/plain, */*'
  http.headers['accept-encoding'] = 'gzip,deflate,sdch'
  http.headers['accept-language'] = 'en-US,en;q=0.8'
  http.headers['cookie'] = circle_cookie
  http.headers['referer'] = "https://www.circle.com/accounts"
  http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
  http.headers['x-customer-id'] = "168900"
  http.headers['x-customer-session-token'] = circle_customer_session_token
end

response = curl.perform

json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)
exchange_rate_object = parsed_json['response']['customer']['exchangeRate']
exchange_rate = parsed_json['response']['customer']['exchangeRate']['USD']['rate']
account_balance_in_btc_raw = parsed_json['response']['customer']['accounts'].first['satoshiAvailableBalance']
account_balance_in_btc_normalized = account_balance_in_btc_raw / 100000000.0
account_balance_in_usd = exchange_rate * account_balance_in_btc_normalized



################################################################################
# Buying a BTC via the Circle API
#
# To make a deposit, we pass the same exchange rate object we got from the
# 'customers' command to the deposit command.  Presumably, if too much time has
# passed between the exchangeRate timestamp and the current time, Circle will
# not allow the deposit to be made.  So those commands should be run back to
# back with as little latency between them as possible
################################################################################


exchange_rate_object_for_deposit_request = exchange_rate_object["USD"]
fiat_value = calculate_fiat_value_for_exchange_rate(exchange_rate, 0.11)

deposit_json_data = {"deposit" =>
    {"fiatAccountId" => fiat_account_id,
      "fiatValue" => fiat_value,
      "exchangeRate" => exchange_rate_object_for_deposit_request
    }
  }

deposit_json_data = deposit_json_data.to_json
content_length = deposit_json_data.length


curl = Curl::Easy.http_post("https://www.circle.com/api/v2/customers/168900/accounts/186074/deposits", deposit_json_data) do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'POST'
  http.headers['path'] = '/api/v2/customers/168900/accounts/186074/deposits'
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
  http.headers['x-customer-id'] = "168900"
  http.headers['x-customer-session-token'] = circle_customer_session_token
end


json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)

deposit_response_status = parsed_json
response_code = deposit_response_status['response']['status']['code']
if response_code == 0
  puts 'Successful Deposit!'
  puts 'Deposit Details:'
  puts deposit_response_status
else
  puts '** ERROR ** Deposit Unsuccessful'
  puts 'Deposit Details:'
  puts deposit_response_status
end


################################################################################
# Selling a BTC via the Circle API
#
# To make a withdraw, we use the 'withdraw' api command.  This is identical to
# the deposit command except we hit the
# '/api/v2/customers/168900/accounts/186074/withdraws' endpoint.
#
################################################################################

exchange_rate_object_for_deposit_request = exchange_rate_object["USD"]
fiat_value = calculate_fiat_value_for_exchange_rate(exchange_rate, 0.11)

withdraw_json_data = {"withdraw" =>
    {"fiatAccountId" => fiat_account_id,
      "fiatValue" => fiat_value,
      "exchangeRate" => exchange_rate_object_for_deposit_request
    }
  }

withdraw_json_data = withdraw_json_data.to_json
content_length = withdraw_json_data.length


curl = Curl::Easy.http_post("https://www.circle.com/api/v2/customers/168900/accounts/186074/withdraws", withdraw_json_data) do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'POST'
  http.headers['path'] = '/api/v2/customers/168900/accounts/186074/withdraws'
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
  http.headers['x-customer-id'] = "168900"
  http.headers['x-customer-session-token'] = circle_customer_session_token
end


json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)

withdraw_response_status = parsed_json
response_code = withdraw_response_status['response']['status']['code']
if response_code == 0
  puts 'Successful Withdraw!'
  puts 'Withdraw Details:'
  puts withdraw_response_status
else
  puts '** ERROR ** Withdraw Unsuccessful'
  puts 'Withdraw Details:'
  puts withdraw_response_status
end



################################################################################
# Sending a BTC to another BTC address using the Circle API
#
#
################################################################################

exchange_rate_object_for_btc_transfer = exchange_rate_object["USD"]
fiat_value = calculate_fiat_value_for_exchange_rate(exchange_rate, 0.11)
satoshi_value = 1000000 * (fiat_value / exchange_rate.to_f).round(18)

btc_transfer_json_data = {"transaction" =>
  {"exchangeRate" => exchange_rate_object_for_btc_transfer,
  "bitcoinOrEmailAddress" => coinbase_btc_address,
  "satoshiValue" => satoshi_value,
  "fiatValue" => fiat_value,
  "currencyCode" => "USD",
  "message" => "sending 0.11 btc (#{fiat_value}) to coinbase."
  }
}

btc_transfer_json_data = btc_transfer_json_data.to_json
content_length = btc_transfer_json_data.length

curl = Curl::Easy.http_post("https://www.circle.com/api/v2/customers/168900/accounts/186074/transactions", btc_transfer_json_data) do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'POST'
  http.headers['path'] = '/api/v2/customers/168900/accounts/186074/transactions'
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
  http.headers['x-customer-id'] = "168900"
  http.headers['x-customer-session-token'] = circle_customer_session_token
end

json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)

btc_transfer_response_status = parsed_json
response_code = btc_transfer_response_status['response']['status']['code']
if response_code == 0
  puts 'Successful BTC tansfer!'
  puts 'Transfer Details:'
  puts btc_transfer_response_status
else
  puts '** ERROR ** BTC Transfer Unsuccessful'
  puts 'Transfer Details:'
  puts btc_transfer_response_status
end









puts 'Exchange Rate:'
puts exchange_rate
puts 'Account Balance in BTC:'
puts account_balance_in_btc_normalized
puts 'Account Balance in USD:'
puts account_balance_in_usd
puts 'Circle Bitcoin Address for Receiving BTC:'
puts circle_bitcoin_address_for_receiving
puts 'Fiat Account Id:'
puts fiat_account_id








