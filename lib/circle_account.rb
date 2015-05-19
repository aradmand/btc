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

    def configure_state!
      circle_client = RbtcArbitrage::Clients::CircleClient.new(circle_account: self, volume: 0.01)

      withdraw_limit = circle_client.withdraw_limit_trailing_seven_days
      self.withdrawn_amount_last_seven_days = withdraw_limit
      if withdrawn_amount_last_seven_days > 400000
        self.state = STATE_MAXED_OUT
      else
        self.state = STATE_ACTIVE
      end
    end

    def btc_address
      circle_client = RbtcArbitrage::Clients::CircleClient.new(circle_account: self, volume: 0.01)
      circle_client.address
    end

    def transfer_btc_to_active_account(active_account)

    end
  end
end


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






