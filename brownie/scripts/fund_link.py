from brownie import SquidSquad
from scritps.helpful_scripts import fund_with_link

def main():
    squid_squad_deployment = SquidSquad[len(SquidSquad) -1]
    fund_with_link(squid_squad_deployment)