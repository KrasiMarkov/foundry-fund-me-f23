//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployfundMe = new DeployFundMe();

        fundMe = deployfundMe.run();

        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsDeployerAddress() public {
        console.log(fundMe.getOwner());
        console.log(address(this));
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();

        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line should revert

        // assert(This tx fails/reverts)
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER

        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayFunders() public {

        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);

        assertEq(funder, USER);
    }

    modifier funded() {

        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {

        vm.prank(USER);

        vm.expectRevert();

        fundMe.withdraw();
    }

  
    function testWithdrawWithSingleFunder() public funded {
        
       //arrange
       uint256 startingFundMeBalance = address(fundMe).balance;
       uint256 startingOwnerBalance = fundMe.getOwner().balance;

       //act
       vm.prank(fundMe.getOwner());
       fundMe.withdraw();
      

       //assert
       uint256 endingFundMeBalance = address(fundMe).balance;
       uint256 endingOwnerBalance = fundMe.getOwner().balance;
       assertEq(endingFundMeBalance, 0);
       assertEq(startingOwnerBalance + startingFundMeBalance,endingOwnerBalance);


    }

    function testWithdrawWithMultipleFunders() public funded {
        
       //arrange
       uint160 startingIndexFunder = 1;
       uint160 numberOfFunders = 10;

        for (uint160 i = startingIndexFunder; i < numberOfFunders; i++) {
           hoax(address(i), SEND_VALUE);
           fundMe.fund{value: SEND_VALUE}();
        }
        
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;


        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance,endingOwnerBalance);

    }
}
