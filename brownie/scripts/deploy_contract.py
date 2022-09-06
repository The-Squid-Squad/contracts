from brownie import SquidSquad
from scripts.helpful_scripts import get_account, fund_with_link

def deploy_contract():
    account = get_account()
    publish_source = False

    squid_squad_deployment = SquidSquad.deploy(
        # config['networks'][network.show_active()][< YOUR CONFIG VALUE HERE (ie. vrf_coordinator, link_token, etc )>]
        {"from": account},
        publish_source = publish_source
    ):
    fund_with_link(squid_squad_deployment)
    return squid_squad_deployment

def main():
    deploy_contract()
    print('contract deployed')

