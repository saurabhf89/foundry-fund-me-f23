//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from  "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{


    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE =  10 ether;
    function setUp() external{

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();//fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.deal(USER,START_BALANCE);
    }

    function testFundMeIsMin5USD() public{
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }
    function testOwnerIsMsgSender() public{
        assertEq(fundMe.getOwnerAddr(),msg.sender);

    }

    function testVersionIsAccurate() public{
        assertEq(fundMe.getVersion(),4);
    }

    function testFundFailsWithoutEnoughETH() public{
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,SEND_VALUE);
    }

    function testAddsFunderToArrayOFFunder() public{
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        assertEq(fundMe.gets_funders(0),USER);
        
    }

    modifier Funded(){
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdra() public Funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public Funded{

        /* Arrange */
        uint256 startingOwnerBalance = fundMe.getOwnerAddr().balance;
        uint256 startingFundMeBalance =  address(fundMe).balance;
        /* Act */
        vm.prank(fundMe.getOwnerAddr());
        fundMe.withdraw();
        /* Assert */
        uint256 endingOwnerBalance = fundMe.getOwnerAddr().balance  ;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance,startingOwnerBalance+startingFundMeBalance);

    }

    function testWithdrawFromMultipleFunders() public Funded{
        
        uint160 numOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numOfFunders; i++){
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwnerAddr().balance;
        uint256 startingFundMeBalance =  address(fundMe).balance;

        vm.prank(fundMe.getOwnerAddr());
        fundMe.withdraw();

          /* Assert */
        uint256 endingOwnerBalance = fundMe.getOwnerAddr().balance  ;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance,startingOwnerBalance+startingFundMeBalance);      




    }
}