pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LavToken.sol";

contract StakeManager {
    // userAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;
    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;
    //track the user’s unrealized yield
    // userAddress => timeStamp
    mapping(address => uint256) public startTime;
    // userAddress => lavBalance
    mapping(address => uint256) public lavBalance;

    string public name = "StakeManager";

    IERC20 public daiToken;
    LavToken public lavToken;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    //inject the token addresses
    constructor(IERC20 _daiToken, LavToken _lavToken) {
        daiToken = _daiToken;
        lavToken = _lavToken;
    }

    /// Core function shells
    function stake() public payable{
        require(
            msg.value > 0 && daiToken.balanceOf(msg.sender) >= msg.value,
            "You cannot stake zero tokens"
        );
        //if already staking, add unrealised yield to lavBalance
        if (isStaking[msg.sender] == true) {
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            lavBalance[msg.sender] += toTransfer;
        }
        //transfer
        console.log(daiToken.allowance(msg.sender, address(this)));
        IERC20(daiToken).approve(msg.sender, msg.value);
        IERC20(daiToken).transferFrom(msg.sender, address(this), msg.value);
        stakingBalance[msg.sender] += msg.value;
        //reset starttime
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, msg.value);
    }

    function unstake(uint256 amount) public {
        require(
            isStaking[msg.sender] =
                true &&
                stakingBalance[msg.sender] >= amount,
            "Nothing to unstake"
        );
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp;
        uint256 balanceTransfer = amount;
        amount = 0;
        stakingBalance[msg.sender] -= balanceTransfer;
        daiToken.transfer(msg.sender, balanceTransfer);
        lavBalance[msg.sender] += yieldTransfer;
        if (stakingBalance[msg.sender] == 0) {
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, amount);
    }

    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(
            toTransfer > 0 || lavBalance[msg.sender] > 0,
            "Nothing to withdraw"
        );

        if (lavBalance[msg.sender] != 0) {
            uint256 oldBalance = lavBalance[msg.sender];
            lavBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;
        lavToken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    }

    function calculateYieldTime(address user) public view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns (uint256){
        uint256 time = calculateYieldTime(user) * 10**18;
        uint256 rate = 86400;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingBalance[user] * timeRate)/ 10**18;
        return rawYield;

    }
}
