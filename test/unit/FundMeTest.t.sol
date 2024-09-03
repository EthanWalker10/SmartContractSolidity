// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;
    DeployFundMe deployFundMe;

    // cheatcode
    address alice = makeAddr("alice");

    // 0.1 ether means 10**17 ether in solidty which doesn't work with float
    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    // avoid the repeated code
    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;

    }

    function setUp() external { 
        // use mock directly
        // MockV3Aggregator mockPriceFeed = new MockV3Aggregator(1, 100);
        // fundMe = new FundMe(address(mockPriceFeed));

        // use the Sepolia address of PriceFeed contract directly
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);


        // use script to deploy
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // cheatcode
        vm.deal(alice, STARTING_BALANCE);   // give alice some money
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);

    }

    function testOwnerIsMsgSender() public {
        // if I deploy the FundMe here, then this equation will be correct
        // assertEq(fundMe.i_owner(), address(this));

        // if I use my script to new FundMe, then this equation will be correct
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value

    }

    // function testFundUpdatesFundDataStrucutre() public {
    //     fundMe.fund{value: 10 ether}();
    //     // uint256 amountFunded = fundMe.getAddressToAmountFunded(msg.sender);   // failed
    //     uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this));   // passed
    //     assertEq(amountFunded, 10 ether);
    // }

    function testFundUpdatesFundDataStrucutre() public {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);

    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(alice);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);

    }

    // without modifier funded
    // function testOnlyOwnerCanWithdraw() public {
    //     vm.prank(alice);
    //     fundMe.fund{value: SEND_VALUE}();

    //     vm.expectRevert();
    //     vm.prank(alice);
    //     fundMe.withdraw();

    // }

    // with modifier funded
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();

    }

    // function testWithdrawFromASingleFunder() public funded {
    //     uint256 startingFundMeBalance = address(fundMe).balance;
    //     uint256 startingOwnerBalance = fundMe.getOwner().balance;

    //     // check the initial balance
    //     console.log(startingFundMeBalance);
    //     console.log(startingOwnerBalance);


    //     vm.startPrank(fundMe.getOwner());
    //     fundMe.withdraw();
    //     vm.stopPrank();

    //     uint256 endingFundMeBalance = address(fundMe).balance;
    //     uint256 endingOwnerBalance = fundMe.getOwner().balance;

    //     // check the initial balance
    //     console.log(endingFundMeBalance);
    //     console.log(endingOwnerBalance);

    //     assertEq(endingFundMeBalance, 0);
    //     assertEq(
    //         startingFundMeBalance + startingOwnerBalance,
    //         endingOwnerBalance
    //     );
    // }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consummed: %d gas", gasUsed);
        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        // why is it still true?
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );

    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);

    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);

    }

    function testPrintStorageData() public {
        for (uint256 i = 0; i < 5; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Vaule at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));

    }


    // function testFloat() public {
    //     console.log(SEND_VALUE);
    // }

}