class CircleAccount

STATE_MAXED_OUT = 'maxed_out'  # > $4,000 traded & less than 7 days have passed since max-out
STATE_ACTIVE = 'active'        #  Account actively being traded
STATE_INACTIVE = 'inactive'    # Account that isn't maxed out, but isn't actively being traded


attr_reader :api_bank_account_id,
  :api_customer_id,
  :api_customer_session_token,
  :id,
  :state,
  :withdrawn_amount_last_7_days

end


########
****** See if the CIRCLE API GIVE US A WAY TO SEE THE withdraw
*** limit as well as how much $$ the account has used toward the limit
########

#### START UP ######
 - Read log to get state of each CircleAccount:
  - Get Wthdraw amount for last 7 days
  - Set Active account
  - Set inactive account(s)
  - Set maxed_out account(s)

###################



###### BUY IN #####
  - Ensure Coinbase Exchange has 1.2 BTC in BTC account
    -if not, buy in up to 1.2 BTC.
  - Ensure Coinbase has 0.6 BTC in BTC account
    -if not, buy in from Coinbase_exchange account and transfer difference into Coinbase
  - Ensure CircleAccount has 1.6 BTC in account
    -if not buy in the difference from Coinbase_exchange, transfer to Coinbase, then transfer to active CircleAccount

###################

####### TRADING ####
  - rbtc_arbitrage trade on Active Account

  - After each loop of the algo, run the SWITCH_ACCOUNTS logic
####################


##### SWITCH ACCOUNTS ####
  - Check non-active CircleAccounts :
    - If CircleAccount is Inactive or maxed_out,
      - transfer all BTC from that account to coinbase Exchange

########################






