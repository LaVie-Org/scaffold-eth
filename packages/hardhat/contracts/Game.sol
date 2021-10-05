pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Accounts.sol";

import "./StakeManager.sol";

contract Game {
    Accounts public accounts;
    StakeManager public stakeManager;

    constructor(Accounts _accounts, StakeManager _stakeManager) {
        accounts = _accounts;
        stakeManager = _stakeManager;
    }

    function newPlayer(
        address player,
        string memory playerStateURI,
        uint8 accountType,
        uint256 amount
    ) external {
        //1. take stake
        //2. create account
        //3. assign items
        //1:15;30
        require(
            accounts.players(player) == 0,
            "La Vie: Player already exists."
        );
        require(
            msg.sender == player,
            "La Vie: Cannot create an account for another Address."
        );
        require(
            accountType == 1 || accountType == 2 || accountType == 3,
            "La Vie: Wrong account type."
        );

        if (accountType == 1) {
            require(amount == 0,"La Vie: Can't stake with accountType 1!");
            createPlayerAccount(player, playerStateURI, accountType);
        } else if (accountType == 2) {
            require(amount == 50 ether,"La Vie: Wrong stake amount!");
            stakeManager.stake(msg.sender, amount, 30);
        } else if (accountType == 3) {
            require(amount >= 100 ether,"La Vie: Wrong stake amount!");
            stakeManager.stake(msg.sender, amount, 60);
        }
        console.log("shouldnt log");
        createPlayerAccount(player, playerStateURI, accountType);
    }

    function deletePlayer(address player, uint256 tokenId) external {
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Cannot delete an unowned account"
        );
        // require(!stakeManager.isStakingBool(player), "La Vie: Unstake first!");
        accounts.deleteAccount(player, tokenId);
    }

    function createPlayerAccount(
        address player,
        string memory playerStateURI,
        uint256 accountType
    ) internal returns (uint256) {
        return accounts.createAccount(player, playerStateURI, accountType);
    }

    function playerReceivesAnItem(
        address player,
        uint256 tokenId,
        uint256 itemId
    ) external {
        require(accounts.itemExists(itemId), "La Vie: item does not exist");
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Account not owned"
        );
        accounts.playerReceivesItemFromGame(player, tokenId, itemId);
    }

    function unstake() external {
        stakeManager.unstake(msg.sender);
    }

    function setVestID(uint64 vestID) external {
        stakeManager.setVestID(msg.sender, vestID);
    }
}
