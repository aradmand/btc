require 'pry'
require 'curb'
require 'active_support'
require 'json'

#Investigations into the Circle API
#export CIRCLE_CUSTOMER_SESSION_TOKEN=

def circle_customer_session_token
  ENV['CIRCLE_CUSTOMER_SESSION_TOKEN']
end

################################################################################
# Generate bitcoin Address for receiving bitcoin
################################################################################


# curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/168900/accounts/186074/address") do |http|
#   http.headers['host'] = 'www.circle.com'
#   http.headers['method'] = 'GET'
#   http.headers['path'] = '/api/v2/customers/168900/accounts/186074/address'
#   http.headers['scheme'] = 'https'
#   http.headers['version'] = 'HTTP/1.1'
#   http.headers['accept'] = 'application/json, text/plain, */*'
#   http.headers['accept-encoding'] = 'gzip,deflate,sdch'
#   http.headers['accept-language'] = 'en-US,en;q=0.8'
#   http.headers['cookie'] = "__cfduid=d0de65aad44eddf6207369c49a488806f1410231774404; optimizelyEndUserId=oeu1416148420288r0.7686132828239352; _ys_trusted=%7B%22_%22%3A%2269b9db727e9281eb49c980e11f349c074fc62c9b%22%7D; optimizelySegments=%7B%7D; optimizelyBuckets=%7B%222169471078%22%3A%222162540652%22%7D; AWSELB=6DE1C52F06D2FAD97948D9C525A94E7AAFA0177A18F0E0AF588D85BA3F707B2324DC85D6467A080C3C55A596F5F12AF54EFBD28ACB95EEF089DAF61F007FEAEB120747ABFC; _ys_session=%7B%22_%22%3A%7B%22value%22%3A%22920567339e61ee8fcd556e0f82d46d209910eca2%22%2C%22customerId%22%3A168900%2C%22expiryDate%22%3A1416279016350%7D%7D; __utma=100973971.7568760.1410231775.1416269203.1416277808.16; __utmb=100973971.3.10.1416277808; __utmc=100973971; __utmz=100973971.1410231775.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); _ys_state=%7B%22_%22%3A%7B%22isEmailVerified%22%3Atrue%2C%22isMfaVerified%22%3Atrue%7D%7D; i18next=en"
#   http.headers['referer'] = "https://www.circle.com/request"
#   http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
#   http.headers['x-customer-id'] = "168900"
#   http.headers['x-customer-session-token'] = circle_customer_session_token
# end

# response = curl.perform
# json_data = ActiveSupport::Gzip.decompress(curl.body_str)
# parsed_json = JSON.parse(json_data)

# circle_bitcoin_address_for_receiving = parsed_json['response']['bitcoinAddress']


################################################################################
# Obtain fiatAccount informaiton
################################################################################

# curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/168900/fiatAccounts") do |http|
#   http.headers['host'] = 'www.circle.com'
#   http.headers['method'] = 'GET'
#   http.headers['path'] = '/api/v2/customers/168900/fiatAccounts'
#   http.headers['scheme'] = 'https'
#   http.headers['version'] = 'HTTP/1.1'
#   http.headers['accept'] = 'application/json, text/plain, */*'
#   http.headers['accept-encoding'] = 'gzip,deflate,sdch'
#   http.headers['accept-language'] = 'en-US,en;q=0.8'
#   http.headers['cookie'] = "__cfduid=d0de65aad44eddf6207369c49a488806f1410231774404; optimizelyEndUserId=oeu1416148420288r0.7686132828239352; _ys_trusted=%7B%22_%22%3A%2269b9db727e9281eb49c980e11f349c074fc62c9b%22%7D; optimizelySegments=%7B%7D; optimizelyBuckets=%7B%222169471078%22%3A%222162540652%22%7D; AWSELB=6DE1C52F06D2FAD97948D9C525A94E7AAFA0177A18F0E0AF588D85BA3F707B2324DC85D6467A080C3C55A596F5F12AF54EFBD28ACB95EEF089DAF61F007FEAEB120747ABFC; _ys_session=%7B%22_%22%3A%7B%22value%22%3A%22920567339e61ee8fcd556e0f82d46d209910eca2%22%2C%22customerId%22%3A168900%2C%22expiryDate%22%3A1416279016350%7D%7D; __utma=100973971.7568760.1410231775.1416269203.1416277808.16; __utmb=100973971.3.10.1416277808; __utmc=100973971; __utmz=100973971.1410231775.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); _ys_state=%7B%22_%22%3A%7B%22isEmailVerified%22%3Atrue%2C%22isMfaVerified%22%3Atrue%7D%7D; i18next=en"
#   http.headers['referer'] = "https://www.circle.com/deposit"
#   http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
#   http.headers['x-customer-id'] = "168900"
#   http.headers['x-customer-session-token'] = circle_customer_session_token
# end

# response = curl.perform

# json_data = ActiveSupport::Gzip.decompress(curl.body_str)
# parsed_json = JSON.parse(json_data)
# fiat_account_array = parsed_json['response']['fiatAccounts']

# # Set fiat_account_id
# fiat_account_id = fiat_account_array.each do |fiat_account|
#   if fiat_account['accountType'] == 'checking' && fiat_account['description'] == "BANK OF AMERICA, N.A. ****4655"
#     fiat_account['id']
#   end
# end

# if fiat_account_id.blank?
#   puts 'ERROR LOCATING FIAT ACCOUNT ID!'
#   exit
# end


################################################################################
# Obtain exchange rate, account balance in btc and account balance in usd
################################################################################




curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/2987692") do |http|
  http.headers['host'] = 'www.circle.com'
  http.headers['method'] = 'GET'
  http.headers['path'] = '/api/v2/customers/2987692'
  http.headers['scheme'] = 'https'
  http.headers['version'] = 'HTTP/1.1'
  http.headers['accept'] = 'application/json, text/plain, */*'
  http.headers['accept-encoding'] = 'gzip,deflate,sdch'
  http.headers['accept-language'] = 'en-US,en;q=0.8'
  http.headers['cookie'] = "__cfduid=dd0b0e482aee0c49bdf3aa44b6ff9b6861416875388; optimizelySegments=%7B%7D; optimizelyEndUserId=oeu1416875393109r0.8295209247153252; optimizelyBuckets=%7B%222169471078%22%3A%222162540652%22%7D; AWSELB=6DE1C52F06D2FAD97948D9C525A94E7AAFA0177A18F0E0AF588D85BA3F707B2324DC85D6467A080C3C55A596F5F12AF54EFBD28ACBCCDDCC74951BAF7F85674EEBA13A9490; _ys_session=%7B%22_%22%3A%7B%22value%22%3A%22720f6bf96c41fb6fe823389373b8d647cb680fb7%22%2C%22customerId%22%3A2987692%2C%22expiryDate%22%3A1416886015488%7D%7D; _ys_trusted=%7B%22_%22%3A%22561552b59c37f3863a743d5e5e9efb40ce1ac9f5%22%7D; i18next=en; _ys_state=%7B%22_%22%3A%7B%22isEmailVerified%22%3Atrue%2C%22isMfaVerified%22%3Atrue%7D%7D; __utma=100973971.1353628286.1416875397.1416875397.1416884811.2; __utmb=100973971.4.10.1416884811; __utmc=100973971; __utmz=100973971.1416875397.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)"
  http.headers['referer'] = "https://www.circle.com/accounts"
  http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
  http.headers['x-customer-id'] = "2987692"
  http.headers['x-customer-session-token'] = "85d99c98bfda89912b35bd8a8a75abadccaa1a0a"
end

response = curl.perform

json_data = ActiveSupport::Gzip.decompress(curl.body_str)
parsed_json = JSON.parse(json_data)
exchange_rate_object = parsed_json['response']['customer']['exchangeRate']
exchange_rate = parsed_json['response']['customer']['exchangeRate']['USD']['rate']
account_balance_in_btc_raw = parsed_json['response']['customer']['accounts'].first['satoshiAvailableBalance']
account_balance_in_btc_normalized = account_balance_in_btc_raw / 100000000.0
account_balance_in_usd = exchange_rate * account_balance_in_btc_normalized
puts exchange_rate_object
puts "your account balance is $ #{account_balance_in_usd}" 





################################################################################
# To make a deposit, we pass the same exchange rate object we got from the 
# 'customers' command to the deposit command.  Presumably, if too much time has
# passed between the exchangeRate timestamp and the current time, Circle will 
# not allow the deposit to be made.  So those commands should be run back to 
# back with as little latency between them as possible
################################################################################


# curl = Curl::Easy.new("https://www.circle.com/api/v2/customers/168900/accounts/186074/deposits") do |http|
#   http.headers['host'] = 'www.circle.com'
#   http.headers['method'] = 'POST'
#   http.headers['path'] = '/api/v2/customers/168900/accounts/186074/deposits'
#   http.headers['scheme'] = 'https'
#   http.headers['version'] = 'HTTP/1.1'
#   http.headers['accept'] = 'application/json, text/plain, */*'
#   http.headers['accept-encoding'] = 'gzip,deflate'
#   http.headers['accept-language'] = 'en-US,en;q=0.8'
#   http.headers['content-length'] = 170
#   http.headers['content-type'] = 'application/json;charset=UTF-8'
#   http.headers['cookie'] = "__cfduid=d0de65aad44eddf6207369c49a488806f1410231774404; optimizelyEndUserId=oeu1416148420288r0.7686132828239352; _ys_trusted=%7B%22_%22%3A%2269b9db727e9281eb49c980e11f349c074fc62c9b%22%7D; optimizelySegments=%7B%7D; optimizelyBuckets=%7B%222169471078%22%3A%222162540652%22%7D; AWSELB=6DE1C52F06D2FAD97948D9C525A94E7AAFA0177A18F0E0AF588D85BA3F707B2324DC85D6467A080C3C55A596F5F12AF54EFBD28ACB95EEF089DAF61F007FEAEB120747ABFC; _ys_session=%7B%22_%22%3A%7B%22value%22%3A%22920567339e61ee8fcd556e0f82d46d209910eca2%22%2C%22customerId%22%3A168900%2C%22expiryDate%22%3A1416279016350%7D%7D; __utma=100973971.7568760.1410231775.1416269203.1416277808.16; __utmb=100973971.3.10.1416277808; __utmc=100973971; __utmz=100973971.1410231775.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); _ys_state=%7B%22_%22%3A%7B%22isEmailVerified%22%3Atrue%2C%22isMfaVerified%22%3Atrue%7D%7D; i18next=en"
#   http.headers['origin'] = 'https://www.circle.com'
#   http.headers['referer'] = "https://www.circle.com/deposit"
#   http.headers['user-agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
#   http.headers['x-customer-id'] = "168900"
#   http.headers['x-customer-session-token'] = circle_customer_session_token

####TODO!! 
# Set request payload to this:
# {"deposit":{"fiatAccountId":"c9f5ff6b-3812-427d-b700-56d28d370db2","fiatValue":37.55,"exchangeRate":{"base":"BTC","quote":"USD","rate":375.28,"timestamp":1416831645360}}}
############


# end

# response = curl.perform
# json_data = ActiveSupport::Gzip.decompress(curl.body_str)
# parsed_json = JSON.parse(json_data)

# circle_bitcoin_address_for_receiving = parsed_json['response']['bitcoinAddress']






# puts 'Exchange Rate:'
# puts exchange_rate
# puts 'Account Balance in BTC:'
# puts account_balance_in_btc_normalized
# puts 'Account Balance in USD:'
# puts account_balance_in_usd
# puts 'Circle Bitcoin Address for Receiving BTC:'
# puts circle_bitcoin_address_for_receiving








