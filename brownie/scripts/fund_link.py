from brownie import TheSquidSquad
from scritps.helpful_scripts import fund_with_link

def main():
    squid_squad_deployment = TheSquidSquad[len(TheSquidSquad) -1]
    fund_with_link(squid_squad_deployment)