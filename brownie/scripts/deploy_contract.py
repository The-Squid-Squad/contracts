from brownie import TheSquidSquad
from scripts.helpful_scripts import get_account, fund_with_link

def deploy_contract():
    account = get_account()
    #publish_source = False
    deployed_contract = TheSquidSquad.deploy(
        "0x2bce784e69d2Ff36c71edcB9F88358dB0DfB55b4",  # vrf coordinator address 
        "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",  # link token address
        "0x0476f9a745b61ea5c0ab224d3a6e4c99f0b02fce4da01143a4f70aa80ae76e8a", # 30 gwei Key Hash
        '100000000000000000', # chainlink fee 0.25 link 
        '12000000000000000', # ticket fee 0.012 eth
        {"from": account},
        publish_source=True
    )
    fund_with_link(deployed_contract)
    return deployed_contract

def main():
    deploy_contract()
    print('contract deployed')

