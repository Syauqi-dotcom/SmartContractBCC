// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/ArenaGelud.sol";

contract ArenaGeludTest is Test {
    ArenaGelud public arenaGelud;
    address public owner;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public carol = address(0x3);

    uint256 public constant DURATION = 1 days;

    function setUp() public {
        console.log("--------------------------------------------------");
        console.log("             SETUP: ArenaGelud Contract            ");
        console.log("--------------------------------------------------");
        owner = address(this);
        arenaGelud = new ArenaGelud(DURATION);
        console.log("Contract Deployed at:", address(arenaGelud));
        console.log("Game End Time:", arenaGelud.gameEndTime());

        // Fund users
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
        console.log("Users Alice, Bob, Carol funded with 100 ETH each");
    }

    function testTeamAWins() public {
        console.log("\n--------------------------------------------------");
        console.log("           TEST: Team A Wins Scenario             ");
        console.log("--------------------------------------------------");

        // Alice bets 1 ETH on A
        console.log("Step 1: Alice bets 1 ETH on Team A");
        vm.prank(alice);
        arenaGelud.bet{value: 1 ether}(true);

        // Bob bets 2 ETH on A
        console.log("Step 2: Bob bets 2 ETH on Team A");
        vm.prank(bob);
        arenaGelud.bet{value: 2 ether}(true);

        // Carol bets 2 ETH on B
        console.log("Step 3: Carol bets 2 ETH on Team B");
        vm.prank(carol);
        arenaGelud.bet{value: 2 ether}(false);

        uint256 totalA = arenaGelud.totalTeamA();
        uint256 totalB = arenaGelud.totalTeamB();
        console.log(
            "Current Standings -> Team A:",
            totalA,
            "| Team B:",
            totalB
        );

        // Warp to end
        console.log("Step 4: Warp time to end game");
        vm.warp(arenaGelud.gameEndTime() + 1);

        // Finalize
        console.log("Step 5: Finalize game");
        arenaGelud.finalizeGame();

        // Check State
        assertTrue(arenaGelud.gameEnded());
        assertTrue(totalA > totalB);
        console.log("Game Finalized. Winner: Team A");

        // Alice claims
        console.log("Step 6: Alice claims reward");
        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        arenaGelud.claimReward();
        uint256 balanceAfter = alice.balance;
        uint256 reward = balanceAfter - balanceBefore;

        console.log("Alice Balance Before:", balanceBefore);
        console.log("Alice Balance After: ", balanceAfter);
        console.log("Alice Reward Claimed:", reward);

        // Expected Verification
        uint256 totalPot = 5 ether;
        uint256 winningTotal = 3 ether;
        uint256 expectedReward = (1 ether * totalPot) / winningTotal;
        console.log("Expected Reward:     ", expectedReward);

        assertEq(reward, expectedReward);
        console.log("Assertion Passed: Reward matches expected value");
    }

    function testDraw() public {
        console.log("\n--------------------------------------------------");
        console.log("             TEST: Draw Scenario                  ");
        console.log("--------------------------------------------------");

        console.log("Step 1: Alice bets 1 ETH on Team A");
        vm.prank(alice);
        arenaGelud.bet{value: 1 ether}(true);

        console.log("Step 2: Bob bets 1 ETH on Team B");
        vm.prank(bob);
        arenaGelud.bet{value: 1 ether}(false);

        console.log(
            "Current Standings -> Team A:",
            arenaGelud.totalTeamA(),
            "| Team B:",
            arenaGelud.totalTeamB()
        );

        console.log("Step 3: Finalize game");
        vm.warp(arenaGelud.gameEndTime() + 1);
        arenaGelud.finalizeGame();
        console.log("Game Finalized. Result: Draw");

        // Alice claims refund
        console.log("Step 4: Alice claims refund");
        uint256 balBefore = alice.balance;
        vm.prank(alice);
        arenaGelud.claimReward();
        console.log("Alice refunded:", alice.balance - balBefore);
        assertEq(alice.balance - balBefore, 1 ether);

        // Bob claims refund
        console.log("Step 5: Bob claims refund");
        uint256 balBob = bob.balance;
        vm.prank(bob);
        arenaGelud.claimReward();
        console.log("Bob refunded:  ", bob.balance - balBob);
        assertEq(bob.balance - balBob, 1 ether);
    }

    function testRevertEarlyWithdraw() public {
        console.log("\n--------------------------------------------------");
        console.log("       TEST: Revert Early Withdraw Check          ");
        console.log("--------------------------------------------------");

        vm.prank(alice);
        arenaGelud.bet{value: 1 ether}(true);
        console.log("Alice placed bet. Game is still ACTIVE.");

        console.log("Attempting to claim reward before game ends...");
        vm.expectRevert("Game not ended yet");
        vm.prank(alice);
        arenaGelud.claimReward();
        console.log("Confirmed: Reverted with 'Game not ended yet'");
    }

    function testRevertLoserWithdraw() public {
        console.log("\n--------------------------------------------------");
        console.log("       TEST: Revert Loser Withdraw Check          ");
        console.log("--------------------------------------------------");

        // A wins
        console.log("Step 1: Setup Game (A Wins)");
        vm.prank(alice);
        arenaGelud.bet{value: 1 ether}(true);
        vm.prank(bob);
        arenaGelud.bet{value: 0.5 ether}(false); // B loses
        console.log("Bets placed. A: 1 ETH, B: 0.5 ETH");

        vm.warp(arenaGelud.gameEndTime() + 1);
        arenaGelud.finalizeGame();
        console.log("Game Finalized.");

        console.log("Step 2: Bob (Loser) attempts to claim reward...");
        vm.expectRevert("No winning bet");
        vm.prank(bob);
        arenaGelud.claimReward();
        console.log("Confirmed: Reverted with 'No winning bet'");
    }
}
