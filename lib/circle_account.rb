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

    def circle_client
      RbtcArbitrage::Clients::CircleClient.new(circle_account: self)
    end

    def configure_state!
      withdraw_limit = circle_client.withdraw_limit_trailing_seven_days
      self.withdrawn_amount_last_seven_days = withdraw_limit
      if withdrawn_amount_last_seven_days > 400000
        self.state = STATE_MAXED_OUT
      else
        self.state = STATE_ACTIVE
      end
    end

    def btc_address
      circle_client.address
    end

    def transfer_btc_to_active_account(active_account)
      return unless active_account.present?

      if active_account.state == STATE_ACTIVE &&
        (self.state == STATE_MAXED_OUT || self.state == STATE_INACTIVE)

        btc_balance, usd_balance = circle_client.balance
        transfer_amount = (btc_balance - 0.0005).round(5)
        if btc_balance.round(5) > 0.0005 && transfer_amount > 0
          circle_client.transfer(active_account.circle_client, {volume: transfer_amount})
        end
      end
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

  # When it is MAXED_OUT, the algo will repeat the process and scan through
  # theh list of eligible accounts in circle_accounts.json to choose the next active
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






