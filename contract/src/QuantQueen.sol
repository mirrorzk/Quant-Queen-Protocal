// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {QuantQueenToken} from "./QuantQueenToken.sol";
/**
 * @title QuantQueen
 * @notice Ticket-gated vault with share accounting (NAV-based). Users stake by burning tickets and may request/execute claims after configured cutoffs.
 * @dev Admin/BOT can configure payout windows and operational transfers. Pausable and role-gated.
 * @custom:security-contact steam@zerobase.pro
 */
contract QuantQueen is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Per-user state container.
     * @param pendingClaimQueueIDs Claim request IDs awaiting execution.
     * @param stakeHistory Append-only user stake records.
     * @param claimHistory Append-only user claim records.
     */
    struct AssetsInfo {
        uint256[] pendingClaimQueueIDs;
        StakeItem[] stakeHistory;
        ClaimItem[] claimHistory;
    }

    /**
     * @notice Single stake record.
     * @param user Staker.
     * @param amount Asset amount staked (token units).
     * @param tier Ticket tier burned for the stake.
     * @param stakeTimestamp Stake time (block timestamp).
     */
    struct StakeItem {
        address user;
        uint256 amount;
        uint256 stakeTimestamp;
    }

    /**
     * @notice Single claim record or queue item.
     * @param isDone True if claim has been executed/finalized.
     * @param user Claim requester.
     * @param assetsAmount Assets (token units) corresponding to shares at execution time.
     * @param shareAmount Shares deducted at request time.
     * @param requestTime Claim requested timestamp.
     * @param claimTime Earliest executable timestamp for the claim.
     */
    struct ClaimItem {
        bool isDone;
        address user;
        uint256 assetsAmount;
        uint256 shareAmount;
        uint256 requestTime;
        uint256 claimTime;
    }

    /// @notice Underlying ERC20 asset.
    IERC20 public token;

    /// @notice LP ERC20 asset.
    QuantQueenToken public quantQueenToken;

    /// @notice Base precision for NAV and conversions (1e18).
    uint256 public constant BASE_NAV = 1e18;

    /// @notice Current net-asset-value per share (scaled by BASE_NAV).
    uint256 public nav;

    /// @notice Current cutoff timestamp (e.g., 24th of month).
    uint256 public currentCutoff;

    /// @notice Next payout timestamp (e.g., 1st of next month).
    uint256 public payout;

    /// @notice Following payout timestamp (e.g., 1st of the month after next).
    uint256 public nextPayout;

    /// @notice Total on-vault assets tracked by the strategy (token units).
    uint256 public totalAssets;

    /// @notice Role that can pause/unpause and toggle features.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role that can move funds to treasury and update payout windows.
    bytes32 public constant BOT_ROLE = keccak256("BOT_ROLE");

    /// @notice Operational treasury receiver.
    address public treasury;

    /// @notice Blacklist flag per user (true = blocked).
    mapping(address user => bool isBlackList) public blackLists;

    /// @notice Per-user assets state.
    mapping(address user => AssetsInfo assetsInfo) internal userAssetsInfo;

    /// @notice Global claim requests by queue ID.
    mapping(uint256 claimQueueId => ClaimItem claimItem) public claimQueue;

    /// @notice Next claim queue ID to assign.
    uint256 public lastClaimQueueId;

    /// @notice Feature switch: staking enabled.
    bool public stakeEnable = true;

    /// @notice Feature switch: claiming enabled.
    bool public claimEnable = true;

    /**
     * @notice Emitted when a stake is executed.
     * @param user Staker.
     * @param stakeAmount Assets staked.
     * @param shareAmount Shares minted.
     * @param currentNav NAV used for conversion.
     */
    event Stake(
        address indexed user,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 currentNav
    );

    /**
     * @notice Emitted when a claim request is created.
     * @param user Claim requester.
     * @param claimId Claim queue ID.
     * @param requestTime Request timestamp.
     * @param claimTime Earliest executable timestamp.
     * @param assetsAmount Assets targeted by the claim (at request time).
     */
    event RequestClaim(
        address indexed user,
        uint256 indexed claimId,
        uint256 requestTime,
        uint256 claimTime,
        uint256 assetsAmount
    );

    /**
     * @notice Emitted when a claim is executed.
     * @param user Claimer.
     * @param assetsAmount Assets paid out (current NAV).
     * @param claimId Claim queue ID.
     * @param shareAmount Shares consumed.
     * @param currentNav NAV used for conversion.
     */
    event Claimed(
        address indexed user,
        uint256 indexed assetsAmount,
        uint256 indexed claimId,
        uint256 shareAmount,
        uint256 currentNav
    );

    /**
     * @notice Emitted when assets are withdrawn by admin.
     * @param _token Token address withdrawn.
     * @param _receiver Receiver address.
     */
    event EmergencyWithdrawal(
        address indexed _token,
        address indexed _receiver
    );

    /**
     * @notice Emitted when funds are transferred to treasury.
     * @param _token Asset token.
     * @param _treasury Treasury receiver.
     * @param _amount Amount transferred.
     */
    event TreasuryReceived(
        address indexed _token,
        address _treasury,
        uint256 indexed _amount
    );

    /**
     * @notice Emitted when a user's blacklist status changes.
     * @param user Target user.
     * @param value New status (true = blacklisted).
     */
    event UpdateBlackList(address indexed user, bool value);

    /// @notice Emitted when staking enabled flag changes.
    event UpdateStakeEnable(bool newValue);

    /// @notice Emitted when claiming enabled flag changes.
    event UpdateClaimEnable(bool newValue);

    /// @notice Emitted when treasury address changes.
    event UpdateTreasury(address _oldTreasury, address _newTreasury);

    /// @notice Emitted when asset token changes.
    event UpdateToken(address _oldToken, address _newToken);

    /// @notice Emitted when NAV changes.
    event UpdateNav(uint256 _oldNav, uint256 _newNav);

    event Mint(address to, uint256 mintAmount);
    /**
     * @notice Emitted when payout windows change.
     * @param currentCutoff New cutoff.
     * @param payout New payout.
     * @param nextPayout New next payout.
     */
    event UpdatePayout(
        uint256 currentCutoff,
        uint256 payout,
        uint256 nextPayout
    );

    // ===== Custom Errors (gas-efficient reverts) =====
    /// @notice Staking is disabled.
    error StakeNotEnable();
    /// @notice Claiming is disabled.
    error ClaimNotEnable();
    /// @notice Stake amount is zero or exceeds tier cap.
    error StakeAmountOutOfRange();
    /// @notice Caller not authorized for this item.
    error InvalidSender();
    /// @notice Insufficient balance/shares.
    error InsufficientBalance();
    /// @notice Claim already executed.
    error AlreadyClaimed();
    /// @notice Claim is still waiting for execution time.
    error ClaimWaiting();
    /// @notice Invalid amount parameter.
    error InvalidAmount();
    /// @notice Zero token address.
    error TokenZeroAddress();
    /// @notice Zero receiver address.
    error ReceiverZeroAddress();
    /// @notice Unsupported ticket tier.
    error UnsupportedTicket();
    /// @notice No-op value (unchanged).
    error ConsistentValue();
    /// @notice Amount must be positive.
    error AmountMustBePositive();
    /// @notice Not enough vault balance.
    error NotEnoughBalance();
    /// @notice Zero address provided.
    error ZeroAddress();
    /// @notice Caller is blacklisted.
    error BlackList();
    /// @notice Invalid cutoff time.
    error InvalidCutoff();
    /// @notice Invalid payout time.
    error InvalidPayout();
    /// @notice Invalid next payout time.
    error InvalidNextPayout();
    /// @notice Invalid NAV value.
    error InvalidNav();
    /// @notice Index out of bounds.
    error InvalidIndex();

    // ===== Modifiers =====

    /// @notice Reverts if caller is blacklisted.
    modifier onlyNotBlackList() {
        require(!blackLists[msg.sender], BlackList());
        _;
    }

    /// @notice Reverts if staking is disabled.
    modifier onlyStakeEnable() {
        require(stakeEnable, StakeNotEnable());
        _;
    }

    /// @notice Reverts if claiming is disabled.
    modifier onlyClaimEnable() {
        require(claimEnable, ClaimNotEnable());
        _;
    }

    /**
     * @notice Initializes the strategy.
     * @param _token Asset token address.
     * @param _treasury Treasury receiver.
     * @param _admin Admin/pauser address.
     * @param _bot BOT role address.
     * @param _currentCutoff Initial cutoff timestamp.
     * @param _payout Initial payout timestamp.
     * @param _nextPayout Initial next payout timestamp.
     */
    constructor(
        address _token,
        address _treasury,
        address _admin,
        address _bot,
        uint256 _currentCutoff,
        uint256 _payout,
        uint256 _nextPayout
    ) {
        require(_token != address(0), ZeroAddress());
        require(_treasury != address(0), ZeroAddress());
        require(_admin != address(0), ZeroAddress());
        require(_bot != address(0), ZeroAddress());
        token = IERC20(_token);
        quantQueenToken = new QuantQueenToken();
        quantQueenToken.transferOwnership(_admin);
        treasury = _treasury;
        nav = BASE_NAV;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(BOT_ROLE, _bot);
        currentCutoff = _currentCutoff;
        payout = _payout;
        nextPayout = _nextPayout;
        emit UpdateTreasury(address(0), _treasury);
        emit UpdateToken(address(0), _token);
        emit UpdatePayout(_currentCutoff, _payout, _nextPayout);
    }

    /**
     * @notice Stake assets by burning a ticket; mints shares at current NAV.
     * @dev Requires caller holds at least one ticket of the given tier.
     * @param stakeAmount Asset amount to stake (token units).
     */
    function stake(
        uint256 stakeAmount
    ) external nonReentrant whenNotPaused onlyNotBlackList onlyStakeEnable {
        AssetsInfo storage assetsInfo = userAssetsInfo[msg.sender];
        token.safeTransferFrom(msg.sender, address(this), stakeAmount);
        uint256 shareAmount = convertToShare(stakeAmount);

        quantQueenToken.mint(msg.sender, shareAmount);
        assetsInfo.stakeHistory.push(
            StakeItem({
                stakeTimestamp: block.timestamp,
                amount: stakeAmount,
                user: msg.sender
            })
        );

        unchecked {
            totalAssets += stakeAmount;
        }
        emit Stake(msg.sender, stakeAmount, shareAmount, nav);
    }

    /**
     * @notice Request a claim; burns shares now and schedules payout at the next window.
     * @param claimAmount Asset amount to claim (converted to shares at request time).
     * @return returnId Claim queue ID assigned.
     */
    function requestClaim(
        uint256 claimAmount
    )
        external
        nonReentrant
        whenNotPaused
        onlyNotBlackList
        returns (uint256 returnId)
    {
        AssetsInfo storage assetsInfo = userAssetsInfo[msg.sender];
        require(claimAmount > 0, InvalidAmount());
        uint256 shareAmount = convertToShare(claimAmount);
        require(quantQueenToken.balanceOf(msg.sender) >= shareAmount, InsufficientBalance());

        ClaimItem storage claimItem = claimQueue[lastClaimQueueId];
        claimItem.user = msg.sender;
        claimItem.assetsAmount = claimAmount;
        claimItem.shareAmount = shareAmount;
        claimItem.requestTime = block.timestamp;
        claimItem.claimTime = block.timestamp <= currentCutoff
            ? payout
            : nextPayout;

        quantQueenToken.burn(msg.sender, shareAmount);
        assetsInfo.pendingClaimQueueIDs.push(lastClaimQueueId);
        unchecked {
            returnId = lastClaimQueueId;
            ++lastClaimQueueId;
        }

        emit RequestClaim(
            msg.sender,
            returnId,
            block.timestamp,
            block.timestamp <= currentCutoff ? payout : nextPayout,
            claimAmount
        );
    }

    /**
     * @notice Execute a matured claim and transfer assets at current NAV.
     * @param claimId Claim queue ID to execute.
     */
    function claim(
        uint256 claimId
    ) external nonReentrant whenNotPaused onlyNotBlackList onlyClaimEnable {
        ClaimItem storage claimItem = claimQueue[claimId];
        AssetsInfo storage assetsInfo = userAssetsInfo[msg.sender];
        require(!claimItem.isDone, AlreadyClaimed());
        require(block.timestamp >= claimItem.claimTime, ClaimWaiting());
        require(claimItem.user == msg.sender, InvalidSender());

        uint256 currentAmount = convertToAssets(claimItem.shareAmount);

        uint256[] memory pendingClaimQueueIDs = userAssetsInfo[msg.sender]
            .pendingClaimQueueIDs;
        for (uint256 i = 0; i < pendingClaimQueueIDs.length; i++) {
            if (pendingClaimQueueIDs[i] == claimId) {
                assetsInfo.pendingClaimQueueIDs[i] = pendingClaimQueueIDs[
                    pendingClaimQueueIDs.length - 1
                ];
                assetsInfo.pendingClaimQueueIDs.pop();
                break;
            }
        }

        assetsInfo.claimHistory.push(
            ClaimItem({
                isDone: true,
                user: msg.sender,
                assetsAmount: currentAmount,
                shareAmount: claimItem.shareAmount,
                requestTime: claimItem.requestTime,
                claimTime: block.timestamp
            })
        );
        totalAssets -= currentAmount;
        
        claimItem.isDone = true;

        token.safeTransfer(msg.sender, currentAmount);

        emit Claimed(
            msg.sender,
            currentAmount,
            claimId,
            claimItem.shareAmount,
            nav
        );
    }

    function mint(address to, uint256 mintAmount)external onlyRole(DEFAULT_ADMIN_ROLE){
        totalAssets += mintAmount;
        uint256 shareAmount = convertToShare(mintAmount);
        quantQueenToken.mint(to, shareAmount);
        emit Mint(to, mintAmount);
    }

    /**
     * @notice Admin emergency withdrawal of any ERC20 from the vault.
     * @param _token Token address to withdraw.
     * @param _receiver Recipient address.
     */
    function emergencyWithdraw(
        address _token,
        address _receiver
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(0), TokenZeroAddress());
        require(_receiver != address(0), ReceiverZeroAddress());

        IERC20(_token).safeTransfer(
            _receiver,
            IERC20(_token).balanceOf(address(this))
        );
        emit EmergencyWithdrawal(_token, _receiver);
    }


    /**
     * @notice Set or clear blacklist flag for a user.
     * @param user Target address.
     * @param value True to blacklist, false to clear.
     */
    function setBlackList(
        address user,
        bool value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blackLists[user] = value;
        emit UpdateBlackList(user, value);
    }

    /**
     * @notice Toggle staking availability.
     * @param value New flag value.
     */
    function setStakeEnable(bool value) external onlyRole(PAUSER_ROLE) {
        require(stakeEnable != value, ConsistentValue());
        stakeEnable = value;
        emit UpdateStakeEnable(value);
    }

    /**
     * @notice Toggle claiming availability.
     * @param value New flag value.
     */
    function setClaimEnable(bool value) external onlyRole(PAUSER_ROLE) {
        require(claimEnable != value, ConsistentValue());
        claimEnable = value;
        emit UpdateClaimEnable(value);
    }

    /**
     * @notice Update treasury address.
     * @param _newTreasury New treasury.
     */
    function setTreasury(
        address _newTreasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newTreasury != address(0), ZeroAddress());
        require(_newTreasury != treasury, ConsistentValue());
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit UpdateTreasury(oldTreasury, _newTreasury);
    }

    /**
     * @notice Update the underlying asset token address.
     * @param _newToken New token address.
     */
    function setToken(address _newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newToken != address(0), ZeroAddress());
        require(_newToken != address(token), ConsistentValue());
        address oldToken = address(token);
        token = IERC20(_newToken);
        emit UpdateToken(oldToken, _newToken);
    }

    /**
     * @notice Update NAV (scaled by BASE_NAV) and rescale total assets accordingly.
     * @param _newNav New NAV value (must be > 0).
     */
    function setNav(uint256 _newNav) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newNav != 0, InvalidNav());
        uint256 oldNav = nav;
        nav = _newNav;
        totalAssets = (totalAssets * _newNav) / oldNav;
        emit UpdateNav(oldNav, _newNav);
    }

    /**
     * @notice Update payout windows (cutoff, payout, next payout).
     * @param _newCutoff New cutoff timestamp.
     * @param _newPayout New payout timestamp (must be > cutoff).
     * @param _newNextPayout New next payout timestamp (must be > payout).
     */
    function setPayout(
        uint256 _newCutoff,
        uint256 _newPayout,
        uint256 _newNextPayout
    ) external onlyRole(BOT_ROLE) {
        require(_newCutoff > block.timestamp, InvalidCutoff());
        require(_newPayout > _newCutoff, InvalidPayout());
        require(_newNextPayout > _newPayout, InvalidNextPayout());
        currentCutoff = _newCutoff;
        payout = _newPayout;
        nextPayout = _newNextPayout;
        emit UpdatePayout(_newCutoff, _newPayout, _newNextPayout);
    }

    /**
     * @notice Transfer assets to treasury (BOT only).
     * @param _amount Amount to transfer.
     */
    function transferToTreasury(uint256 _amount) external onlyRole(BOT_ROLE) {
        require(_amount > 0, AmountMustBePositive());
        require(_amount <= token.balanceOf(address(this)), NotEnoughBalance());

        token.safeTransfer(treasury, _amount);

        emit TreasuryReceived(address(token), treasury, _amount);
    }

    /// @notice Pause functions guarded by `whenNotPaused`.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause functions guarded by `whenNotPaused`.
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice View assets claimable by a user (converts shares to assets by current NAV).
     * @param _user User address to query.
     * @return Amount of assets claimable now (not including pending claims).
     */
    function getClaimableAssets(address _user) external view returns (uint256) {
        return convertToAssets(quantQueenToken.balanceOf(_user));
    }

    /**
     * @notice Get a user's stake record by index.
     * @param _user Address to query.
     * @param _index Index into stake history.
     * @return Stake record at `_index`.
     */
    function getStakeHistory(
        address _user,
        uint256 _index
    ) external view returns (StakeItem memory) {
        AssetsInfo memory stakeInfo = userAssetsInfo[_user];
        require(_index < stakeInfo.stakeHistory.length, InvalidIndex());

        return stakeInfo.stakeHistory[_index];
    }

    /**
     * @notice Get a user's claim record by index.
     * @param _user Address to query.
     * @param _index Index into claim history.
     * @return Claim record at `_index`.
     */
    function getClaimHistory(
        address _user,
        uint256 _index
    ) external view returns (ClaimItem memory) {
        AssetsInfo memory stakeInfo = userAssetsInfo[_user];
        require(_index < stakeInfo.claimHistory.length, InvalidIndex());

        return stakeInfo.claimHistory[_index];
    }

    /**
     * @notice Get total number of stake records for a user.
     * @param _user Address to query.
     * @return Length of stake history.
     */
    function getStakeHistoryLength(
        address _user
    ) external view returns (uint256) {
        AssetsInfo memory stakeInfo = userAssetsInfo[_user];

        return stakeInfo.stakeHistory.length;
    }

    /**
     * @notice Get total number of claim records for a user.
     * @param _user Address to query.
     * @return Length of claim history.
     */
    function getClaimHistoryLength(
        address _user
    ) public view returns (uint256) {
        AssetsInfo memory stakeInfo = userAssetsInfo[_user];

        return stakeInfo.claimHistory.length;
    }

    /**
     * @notice Get all pending claim queue IDs for a user.
     * @param _user Address to query.
     * @return Array of pending claim IDs.
     */
    function getClaimQueueIDs(
        address _user
    ) external view returns (uint256[] memory) {
        AssetsInfo memory assetsInfo = userAssetsInfo[_user];
        return assetsInfo.pendingClaimQueueIDs;
    }

    /**
     * @notice Convert shares to assets using current NAV.
     * @param shareAmount Amount of shares.
     * @return Asset amount (token units).
     */
    function convertToAssets(
        uint256 shareAmount
    ) public view returns (uint256) {
        return (shareAmount * nav) / BASE_NAV;
    }

    /**
     * @notice Convert assets to shares using current NAV.
     * @param assetAmount Asset amount (token units).
     * @return Share amount.
     */
    function convertToShare(uint256 assetAmount) public view returns (uint256) {
        return (assetAmount * BASE_NAV) / nav;
    }
}
