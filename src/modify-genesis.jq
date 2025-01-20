#!/usr/bin/env jq

def modify_genesis:
    .genesis_time = env.GENESIS_TIME |
    .app_state.bank.supply = [{"denom": env.DEFAULT_DENOM, "amount": env.TOTAL_SUPPLY}];

def modify_genesis_xion:
    .app_state.abstractaccount.params.allow_all_code_ids = false |
    .app_state.abstractaccount.params.allowed_code_ids = ["1"] |
    .app_state.feeabs.epochs = [] |
    .app_state.feeabs.params.native_ibced_in_osmosis = "" |
    .app_state.feeabs.params.chain_name = "" |
    .app_state.jwk.audienceList = [{"aud": env.JWK_AUD, "key": env.JWK_KEY, "admin": env.JWK_ADMIN}] |
    modify_genesis;

def modify_genesis_xion_testnet_1: 
    .app_state.globalfee.params.minimum_gas_prices = [{"denom": env.DEFAULT_DENOM, "amount": "0.001000000000000000"}] |
    .app_state.gov.params.expedited_voting_period = "3600s" |
    .app_state.gov.params.expedited_min_deposit = [{"denom": env.DEFAULT_DENOM, "amount": "5000000000"}] |
    .app_state.gov.params.min_deposit = [{"denom": env.DEFAULT_DENOM, "amount": "1000000000"}] |
    .app_state.gov.params.max_deposit_period = "24h0m0s" |
    .app_state.slashing.params.signed_blocks_window = "10000" | 
    .app_state.slashing.params.slash_fraction_double_sign = "0.050000000000000000" | 
    .app_state.slashing.params.slash_fraction_downtime = "0.001000000000000000" | 
    .app_state.staking.params.unbonding_time = "21600s" |
    .app_state.staking.params.max_validators = 35 |
    .app_state.staking.params.min_commission_rate = "0.050000000000000000" |
    .app_state.tokenfactory.params.denom_creation_fee = [{"denom": env.DEFAULT_DENOM, "amount": "1000000000"}] |
    .consensus.params.block.max_bytes = "22020096" |
    .consensus.params.block.max_gas = "-1" |
    modify_genesis_xion;

# def add_code_id: 
#     .app_state.wasm.codes += [{
#         "code_id": $code_id,
#         "code_bytes": $code_bytes,
#         "creator": $creator_address,
#         "instantiate_permission": {
#             "permission": "Everybody",
#             "address": "",
#             "addresses": []
#         }
#     }];

def add_genesis_account: 
    .app_state["auth"]["accounts"] += [{
        "@type": "/cosmos.auth.v1beta1.BaseAccount", 
        "address": $vars.addr, 
        "pub_key": null, 
        "account_number": ($vars.account_number | tostring), 
        "sequence": "0"
    }];

def add_genesis_balance: 
    .app_state["bank"]["balances"] += [{
        "address": $vars.addr, 
        "coins": $vars.coins
    }];

def main:
    if $execute == "modify_genesis" then modify_genesis
    elif $execute == "modify_genesis_xion" then modify_genesis_xion
    elif $execute == "modify_genesis_xion_testnet_1" then modify_genesis_xion_testnet_1
    # elif $func == "add_code_id" then add_code_id
    elif $execute == "add_genesis_account" then add_genesis_account
    elif $execute == "add_genesis_balance" then add_genesis_balance
    else error("Unknown function: " + $execute)
    end;

main
