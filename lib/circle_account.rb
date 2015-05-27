module CircleAccount
  class CircleAccount

    STATE_MAXED_OUT = 'maxed_out'  # > $4,000 traded & less than 7 days have passed since max-out
    STATE_ACTIVE = 'active'        #  Account actively being traded
    STATE_INACTIVE = 'inactive'    # Account that isn't maxed out, but isn't actively being traded

    attr_accessor :api_bank_account_id,
      :api_customer_id,
      :api_customer_session_token,
      :email,
      :state,
      :withdrawn_amount_last_seven_days

    def initialize(api_bank_account_id, api_customer_id, api_customer_session_token, state, withdrawn_amount_last_seven_days, email)
      @api_bank_account_id = api_bank_account_id
      @api_customer_id = api_customer_id
      @api_customer_session_token = api_customer_session_token
      @email = email
      @state = state
      @withdrawn_amount_last_seven_days = withdrawn_amount_last_seven_days
    end

    def self.consolidate_btc_balances_to_account(active_circle_account)
      circle_account_hash = read_accounts_configuration_file
      return nil unless circle_account_hash

      # Determine the state of each account
      circle_accounts_array = set_circle_accounts_array(circle_account_hash)

      # Iterate through each account and transfer BTC funds if necessary
      circle_accounts_array.each do |circle_account|
        next if circle_account.email == active_circle_account.email
        circle_account.transfer_btc_to_active_account(active_circle_account)
      end
    end

    def self.find_active_account(previous_active_account = nil)
      begin
        if previous_active_account && previous_active_account.still_active?
          previous_active_account.configure_state!
          return previous_active_account
        end
      rescue => e
        puts 'Exception while determining if previous CircleAccount is still active'
        puts e.message
      end

      circle_account_hash = read_accounts_configuration_file
      return nil unless circle_account_hash

      # Determine the state of each account
      circle_accounts_array = set_circle_accounts_array(circle_account_hash)

      # Set only one account to active
      circle_accounts_array.each do |account|
        if account.state == STATE_ACTIVE
          circle_accounts_array.each do |inactive_account|
            unless account == inactive_account || inactive_account.state == STATE_MAXED_OUT
              inactive_account.state = STATE_INACTIVE
            end
          end
        end
      end

      active_circle_account = circle_accounts_array.select do |account|
        account.state == STATE_ACTIVE
      end.try(:first)
    end

    def circle_client(config = {})
      RbtcArbitrage::Clients::CircleClient.new({circle_account: self}.merge(config))
    end

    def configure_state!
      withdraw_limit = circle_client.withdraw_limit_trailing_seven_days(false)
      self.withdrawn_amount_last_seven_days = withdraw_limit
      if withdrawn_amount_last_seven_days > 400000
        self.state = STATE_MAXED_OUT
      else
        self.state = STATE_ACTIVE
      end
    end

    def still_active?
      withdraw_limit = circle_client.withdraw_limit_trailing_seven_days(false)
      withdraw_limit < 400000
    end

    def btc_address
      circle_client.address
    end

    def transfer_btc_to_active_account(active_account)
      return unless active_account.present?

      if active_account.state == STATE_ACTIVE
        btc_balance, usd_balance = circle_client.balance
        transfer_amount = (btc_balance - 0.0005).round(5)
        if btc_balance.round(5) > 0.0005 && transfer_amount > 0
          puts "Transferring #{transfer_amount} BTC to Active Circle Account [#{active_account.email}]"
          circle_client.transfer(active_account.circle_client, {volume: transfer_amount})
        end
      end
    end

    private

    def self.read_accounts_configuration_file
      begin
        circle_accounts_file = File.read('lib/circle_accounts.json')
        circle_account_hash = JSON.parse(circle_accounts_file)
      rescue => e
        puts 'Exception while parsing confguration file circle_accounts.json.  Please check for properly formatted JSON!'
        puts e.message
        return nil
      end
    end

    def self.set_circle_accounts_array(circle_account_hash)
      circle_accounts_array = []

      # Determine the state of each account
      circle_account_hash.each do |email, account|
        circle_account = CircleAccount.new(
          account['api_bank_account_id'],
          account['api_customer_id'],
          account['api_customer_session_token'],
          account['state'],
          account['withdrawn_amount_last_seven_days'],
          email
        )

        begin
          circle_account.configure_state!
        rescue => e
          puts "Unable to configure account [ #{email} ]"
          next
        end

        circle_accounts_array << circle_account
      end
      circle_accounts_array
    end
  end
end


#################################
#  Adding a new Circle Account
#
#  1. Add email address and login credentials to google doc
#  2. Add entry in circle_accounts.json
#  3. Log in to new Circle Account and turn 2 factor auth OFF for withdraws and transfers
#################################


# THE ALGORITHM:
  # The algo will read in the circle_accounts.json file to find the first account
  # eligible to be traded and set it to active.

  # All other accounts will be marked as either INACTIVE or MAXED_OUT

  # The active account will be traded until it becomes MAXED_OUT

  # The algo will transfer outstanding BTC balances from all MAXED_OUT or INACTIVE
  #  accounts to the current ACTIVE account

  # When it is MAXED_OUT, the algo will repeat the process and scan through
  # the list of eligible accounts in circle_accounts.json to choose the next active
  # account to trade.


# ########
# ****** See if the CIRCLE API GIVE US A WAY TO SEE THE withdraw
# *** limit as well as how much $$ the account has used toward the limit
# ########

# #### START UP ######
#  - Read log to get state of each CircleAccount:
#   - Get Wthdraw amount for last 7 days
#   - Set Active account
#   - Set inactive account(s)
#   - Set maxed_out account(s)

# ###################



# ###### BUY IN #####
#   - Ensure Coinbase Exchange has 1.2 BTC in BTC account
#     -if not, buy in up to 1.2 BTC.
#   - Ensure Coinbase has 0.6 BTC in BTC account
#     -if not, buy in from Coinbase_exchange account and transfer difference into Coinbase
#   - Ensure CircleAccount has 1.6 BTC in account
#     -if not buy in the difference from Coinbase_exchange, transfer to Coinbase, then transfer to active CircleAccount

# ###################

# ####### TRADING ####
#   - rbtc_arbitrage trade on Active Account

#   - After each loop of the algo, run the SWITCH_ACCOUNTS logic
# ####################


# ##### SWITCH ACCOUNTS ####
#   - Check non-active CircleAccounts :
#     - If CircleAccount is Inactive or maxed_out,
#       - transfer all BTC from that account to Active Account
#         -If no other accounts are active, then transfer BTC back to Coinbase

# ########################






