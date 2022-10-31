pragma solidity 0.8.11;

contract PriceBettersBank {
    uint8 private priceBettersCount;
    mapping (address => uint) private balances;
    address public owner;

    event LogDepositMade(address indexed accountAddress, uint amount);

    constructor() public payable {
        /* Set the owner to the creator of this contract */
        owner = msg.sender;
        priceBettersCount = 0;
    }

    function deposit() public payable returns (uint) {
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return balances[msg.sender];
    }


    function withdraw(uint withdrawAmount, address payable _withdrawAddress) public returns (uint remainingBal) {
        // Check enough balance available, otherwise just return balance
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            _withdrawAddress.transfer(withdrawAmount);
        }
        return balances[msg.sender];
    }

    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function depositsBalance() public view returns (uint) {
        return address(this).balance;
    }
}