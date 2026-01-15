// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArenaGelud {
    enum GameState {
        ACTIVE,
        TEAM_A_WON,
        TEAM_B_WON,
        DRAW
    }

    address public owner;
    uint256 public gameEndTime;
    uint256 public totalTeamA;
    uint256 public totalTeamB;
    bool public gameEnded;

    mapping(address => uint256) public balancesA;
    mapping(address => uint256) public balancesB;

    event BetPlaced(address indexed user, bool onTeamA, uint256 amount);
    event GameEnded(GameState result, uint256 totalA, uint256 totalB);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier onlyActive() {
        require(block.timestamp < gameEndTime, "Game has ended");
        require(!gameEnded, "Game already finalized");
        _;
    }

    constructor(uint256 _duration) {
        owner = msg.sender;
        gameEndTime = block.timestamp + _duration;
    }

    function bet(bool _onTeamA) external payable onlyActive {
        require(msg.value > 0, "Bet amount must be greater than 0");

        if (_onTeamA) {
            totalTeamA += msg.value;
            balancesA[msg.sender] += msg.value;
        } else {
            totalTeamB += msg.value;
            balancesB[msg.sender] += msg.value;
        }

        emit BetPlaced(msg.sender, _onTeamA, msg.value);
    }

    function finalizeGame() external onlyOwner {
        require(block.timestamp >= gameEndTime, "Game is still active");
        require(!gameEnded, "Game already finalized");

        gameEnded = true;
        GameState result;

        if (totalTeamA > totalTeamB) {
            result = GameState.TEAM_A_WON;
        } else if (totalTeamB > totalTeamA) {
            result = GameState.TEAM_B_WON;
        } else {
            result = GameState.DRAW;
        }

        emit GameEnded(result, totalTeamA, totalTeamB);
    }

    function claimReward() external {
        require(gameEnded, "Game not ended yet");

        uint256 reward = 0;
        uint256 userBetA = balancesA[msg.sender];
        uint256 userBetB = balancesB[msg.sender];

        balancesA[msg.sender] = 0;
        balancesB[msg.sender] = 0;

        GameState result;
        if (totalTeamA > totalTeamB) {
            result = GameState.TEAM_A_WON;
        } else if (totalTeamB > totalTeamA) {
            result = GameState.TEAM_B_WON;
        } else {
            result = GameState.DRAW;
        }

        if (result == GameState.TEAM_A_WON) {
            require(userBetA > 0, "No winning bet");
            uint256 totalPot = totalTeamA + totalTeamB;
            reward = (userBetA * totalPot) / totalTeamA;
        } else if (result == GameState.TEAM_B_WON) {
            require(userBetB > 0, "No winning bet");
            uint256 totalPot = totalTeamA + totalTeamB;
            reward = (userBetB * totalPot) / totalTeamB;
        } else {
            reward = userBetA + userBetB;
            require(reward > 0, "No bets to refund");
        }

        require(reward > 0, "No reward to claim");

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");
    }
}
