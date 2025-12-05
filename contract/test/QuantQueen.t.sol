// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {QuantQueen} from "../src/QuantQueen.sol";
import {QuantQueenToken} from "../src/QuantQueenToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Minimal mintable ERC20 used as the underlying asset token for tests.
contract TestToken is IERC20 {
    string public name = "TestToken";
    string public symbol = "TT";
    uint8 public immutable decimals = 18;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 a = allowance[from][msg.sender];
        require(a >= amount, "allowance");
        if (a != type(uint256).max) allowance[from][msg.sender] = a - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract QuantQueenTest is Test {
    // actors
    address internal admin = address(this);
    address internal bot = address(0xB07);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal treasury = address(0xffff);

    // contracts
    TestToken internal token;
    QuantQueen internal quantQueen;

    // time windows
    uint256 internal cutoff;
    uint256 internal payout;
    uint256 internal nextPayout;

    // constants
    uint256 internal constant ONE = 1e18;

    function setUp() public {
        vm.label(admin, "ADMIN");
        vm.label(bot, "BOT");
        vm.label(alice, "ALICE");
        vm.label(bob, "BOB");
        vm.label(treasury, "TREASURY");

        // baseline timestamps
        uint256 t0 = block.timestamp;
        cutoff = t0 + 2 days;
        payout = t0 + 9 days;
        nextPayout = t0 + 40 days;

        // deploy underlying token and fund accounts
        token = new TestToken();
        token.mint(alice, 10_000_000 * ONE);
        token.mint(bob, 10_000_000 * ONE);
        token.mint(address(this), 10_000_000 * ONE);

        // deploy quantQueen
        quantQueen = new QuantQueen(
            address(token),
            treasury,
            admin, // DEFAULT_ADMIN_ROLE & PAUSER_ROLE
            bot,   // BOT_ROLE
            cutoff,
            payout,
            nextPayout
        );

        // prepare approvals for users
        vm.startPrank(alice);
        token.approve(address(quantQueen), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(quantQueen), type(uint256).max);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               Helpers
    //////////////////////////////////////////////////////////////*/

    function _quant() internal view returns (QuantQueenToken) {
        return quantQueen.quantQueenToken();
    }

    function _claimItem(uint256 id)
        internal
        view
        returns (
            bool isDone,
            address user_,
            uint256 assetsAmount,
            uint256 shareAmount,
            uint256 requestTime,
            uint256 claimTime
        )
    {
        (isDone, user_, assetsAmount, shareAmount, requestTime, claimTime) = quantQueen.claimQueue(id);
    }

    /*//////////////////////////////////////////////////////////////
                           Happy path full flow
    //////////////////////////////////////////////////////////////*/

    function test_stake_requestClaim_claim_fullFlow() public {
        uint256 amount = 50_000 * ONE;

        // stake
        vm.prank(alice);
        quantQueen.stake(amount);

        // share minted at NAV=1
        QuantQueenToken qq = _quant();
        assertEq(qq.balanceOf(alice), amount, "shares minted = amount");
        assertEq(quantQueen.totalAssets(), amount, "totalAssets updated");

        // request claim half
        vm.prank(alice);
        uint256 claimId = quantQueen.requestClaim(amount / 2);

        // shares burned on request
        assertEq(qq.balanceOf(alice), amount - amount / 2, "shares reduced after request");

        // pending queue updated
        uint256[] memory ids = quantQueen.getClaimQueueIDs(alice);
        assertEq(ids.length, 1);
        assertEq(ids[0], claimId);

        // can't claim before window
        vm.expectRevert(QuantQueen.ClaimWaiting.selector);
        vm.prank(alice);
        quantQueen.claim(claimId);

        // fast forward to claimTime
        (, , , , , uint256 claimTime) = _claimItem(claimId);
        vm.warp(claimTime);

        // claim
        uint256 balBefore = token.balanceOf(alice);
        vm.prank(alice);
        quantQueen.claim(claimId);

        uint256 received = token.balanceOf(alice) - balBefore;
        assertEq(received, amount / 2, "received principal @ NAV=1");
        assertEq(quantQueen.totalAssets(), amount - received, "totalAssets decreased");
        // removed from pending
        uint256[] memory idsAfter = quantQueen.getClaimQueueIDs(alice);
        assertEq(idsAfter.length, 0);
    }

    /*//////////////////////////////////////////////////////////////
                               NAV dynamics
    //////////////////////////////////////////////////////////////*/

    function test_requestClaim_then_NAV_down_affectsPayout() public {
        uint256 amount = 100_000 * ONE;

        vm.prank(alice);
        quantQueen.stake(amount);

        // request 60%
        vm.prank(alice);
        uint256 claimId = quantQueen.requestClaim((amount * 60) / 100);

        // NAV down to 0.8
        quantQueen.setNav((quantQueen.nav() * 8) / 10);

        // advance to claim time
        (, , , , , uint256 claimTime) = _claimItem(claimId);
        vm.warp(claimTime);

        // expected payout uses current NAV and stored shares
        (, , , uint256 shares, , ) = _claimItem(claimId);
        uint256 expected = quantQueen.convertToAssets(shares);

        uint256 before = token.balanceOf(alice);
        vm.prank(alice);
        quantQueen.claim(claimId);
        uint256 got = token.balanceOf(alice) - before;
        assertEq(got, expected, "paid at new NAV");
    }

    function test_requestClaim_then_NAV_up_affectsPayout() public {
        uint256 amount = 80_000 * ONE;

        vm.prank(alice);
        quantQueen.stake(amount);

        vm.prank(alice);
        uint256 claimId = quantQueen.requestClaim(amount / 4); // 25%

        // NAV up to 1.25
        quantQueen.setNav((quantQueen.nav() * 125) / 100);

        (, , , , , uint256 claimTime) = _claimItem(claimId);
        vm.warp(claimTime);

        (, , , uint256 shares, , ) = _claimItem(claimId);
        uint256 expected = quantQueen.convertToAssets(shares);

        uint256 before = token.balanceOf(alice);
        vm.prank(alice);
        quantQueen.claim(claimId);
        uint256 got = token.balanceOf(alice) - before;
        assertEq(got, expected, "paid at higher NAV");
    }

    /*//////////////////////////////////////////////////////////////
                        Pause / Feature switches / Blacklist
    //////////////////////////////////////////////////////////////*/

    function test_pause_blocksStakeAndClaimPaths() public {
        // pause whole contract (whenNotPaused)
        quantQueen.pause();

        vm.expectRevert(); // Pausable: paused
        vm.prank(alice);
        quantQueen.stake(1 * ONE);

        quantQueen.unpause();

        // toggle stakeEnable
        quantQueen.setStakeEnable(false);
        vm.expectRevert(QuantQueen.StakeNotEnable.selector);
        vm.prank(alice);
        quantQueen.stake(1 * ONE);

        quantQueen.setStakeEnable(true);
        vm.prank(alice);
        quantQueen.stake(1 * ONE);

        // toggle claimEnable
        vm.prank(alice);
        uint256 id = quantQueen.requestClaim(1 * ONE);

        quantQueen.setClaimEnable(false);

        (, , , , , uint256 claimTime) = _claimItem(id);
        vm.warp(claimTime);

        vm.expectRevert(QuantQueen.ClaimNotEnable.selector);
        vm.prank(alice);
        quantQueen.claim(id);
    }

    function test_blacklist_blocksUser() public {
        quantQueen.setBlackList(alice, true);

        vm.expectRevert(QuantQueen.BlackList.selector);
        vm.prank(alice);
        quantQueen.stake(1 * ONE);

        // allow again
        quantQueen.setBlackList(alice, false);
        vm.prank(alice);
        quantQueen.stake(5 * ONE);

        // now request claim but blacklist blocks it at entry
        quantQueen.setBlackList(alice, true);
        vm.expectRevert(QuantQueen.BlackList.selector);
        vm.prank(alice);
        quantQueen.requestClaim(1 * ONE);
    }

    /*//////////////////////////////////////////////////////////////
                         Admin / BOT guarded functions
    //////////////////////////////////////////////////////////////*/

    function test_onlyBOT_setPayout_and_transferToTreasury() public {
        // non-bot cannot set payout
        vm.expectRevert(); // AccessControl revert
        quantQueen.setPayout(block.timestamp + 3 days, block.timestamp + 10 days, block.timestamp + 40 days);

        // bot can
        vm.prank(bot);
        quantQueen.setPayout(block.timestamp + 3 days, block.timestamp + 10 days, block.timestamp + 40 days);

        // non-bot cannot transfer to treasury
        vm.expectRevert(); // AccessControl revert
        quantQueen.transferToTreasury(1);

        // fund quantQueen and transfer by bot
        token.mint(address(quantQueen), 123 * ONE);
        uint256 before = token.balanceOf(treasury);
        vm.prank(bot);
        quantQueen.transferToTreasury(100 * ONE);
        assertEq(token.balanceOf(treasury) - before, 100 * ONE, "treasury received");
    }

    function test_emergencyWithdraw_adminOnly() public {
        // fund quantQueen
        token.mint(address(quantQueen), 500 * ONE);

        uint256 before = token.balanceOf(address(this));
        quantQueen.emergencyWithdraw(address(token), address(this));
        assertEq(token.balanceOf(address(this)) - before, 500 * ONE, "swept");
        assertEq(token.balanceOf(address(quantQueen)), 0, "emptied");
    }

    function test_setTreasury_and_setToken() public {
        // update treasury
        address newTreasury = address(0xDEAD);
        quantQueen.setTreasury(newTreasury);
        // update token
        TestToken token2 = new TestToken();
        token2.mint(alice, 1_000_000 * ONE);

        // cannot set zero
        vm.expectRevert(QuantQueen.ZeroAddress.selector);
        quantQueen.setToken(address(0));

        quantQueen.setToken(address(token2));
        assertEq(address(quantQueen.token()), address(token2), "token updated");
    }

    /*//////////////////////////////////////////////////////////////
                        Getters / History / Errors
    //////////////////////////////////////////////////////////////*/

    function test_getters_and_InvalidIndex() public {
        // stake once
        vm.prank(alice);
        quantQueen.stake(42 * ONE);

        // stake history length
        uint256 n = quantQueen.getStakeHistoryLength(alice);
        assertEq(n, 1);


        // out-of-bounds stake history
        vm.expectRevert(QuantQueen.InvalidIndex.selector);
        quantQueen.getStakeHistory(alice, 1);

        // claim history initially 0
        assertEq(quantQueen.getClaimHistoryLength(alice), 0);
        vm.expectRevert(QuantQueen.InvalidIndex.selector);
        quantQueen.getClaimHistory(alice, 0);
    }


    /*//////////////////////////////////////////////////////////////
                        Conversions and claimable
    //////////////////////////////////////////////////////////////*/

    function test_convertToShare_and_convertToAssets_roundtrip() public {
        uint256 nav = quantQueen.nav(); // 1e18 initial
        assertEq(nav, 1e18);

        // at NAV 1, assets == shares
        uint256 shares = quantQueen.convertToShare(123 * ONE);
        assertEq(shares, 123 * ONE);

        uint256 assets = quantQueen.convertToAssets(shares);
        assertEq(assets, 123 * ONE);

        // change NAV to 1.25
        quantQueen.setNav((nav * 125) / 100);

        // assets -> shares downscaled
        uint256 shares2 = quantQueen.convertToShare(125 * ONE);
        assertEq(shares2, 100 * ONE); // 125 / 1.25

        // shares -> assets upscaled
        uint256 assets2 = quantQueen.convertToAssets(100 * ONE);
        assertEq(assets2, 125 * ONE);
    }

    function test_getClaimableAssets_reflectsShareBalance() public {
        vm.prank(alice);
        quantQueen.stake(10_000 * ONE);

        // at NAV 1, claimable == shares == 10k
        uint256 claimable = quantQueen.getClaimableAssets(alice);
        assertEq(claimable, 10_000 * ONE);

        // after requesting claim of 4k (burn shares), claimable == 6k
        vm.prank(alice);
        quantQueen.requestClaim(4_000 * ONE);
        uint256 claimable2 = quantQueen.getClaimableAssets(alice);
        assertEq(claimable2, 6_000 * ONE);

        // raise NAV to 2.0, claimable grows to 12k (for remaining shares)
        quantQueen.setNav(2 * ONE);
        uint256 claimable3 = quantQueen.getClaimableAssets(alice);
        assertEq(claimable3, 12_000 * ONE);
    }

    /*//////////////////////////////////////////////////////////////
                           Payout param validations
    //////////////////////////////////////////////////////////////*/

    function test_setPayout_requires_ordering() public {
        // by bot with invalid ordering should revert
        vm.prank(bot);
        vm.expectRevert(QuantQueen.InvalidCutoff.selector);
        quantQueen.setPayout(block.timestamp - 1, block.timestamp + 1 days, block.timestamp + 2 days);

        vm.prank(bot);
        vm.expectRevert(QuantQueen.InvalidPayout.selector);
        quantQueen.setPayout(block.timestamp + 1 days, block.timestamp + 1 days, block.timestamp + 2 days);

        vm.prank(bot);
        vm.expectRevert(QuantQueen.InvalidNextPayout.selector);
        quantQueen.setPayout(block.timestamp + 1 days, block.timestamp + 2 days, block.timestamp + 1 days);

        // valid
        vm.prank(bot);
        quantQueen.setPayout(block.timestamp + 1 days, block.timestamp + 3 days, block.timestamp + 10 days);
    }

    /*//////////////////////////////////////////////////////////////
                      Claim path ownership/validation
    //////////////////////////////////////////////////////////////*/

    function test_claim_reverts_if_wrong_sender_or_reclaimed() public {
        uint256 amount = 10_000 * ONE;

        vm.prank(alice);
        quantQueen.stake(amount);

        vm.prank(alice);
        uint256 claimId = quantQueen.requestClaim(3_000 * ONE);

        (, address user_, , , , uint256 claimTime) = _claimItem(claimId);
        assertEq(user_, alice);

        vm.warp(claimTime);

        // wrong sender cannot claim
        vm.expectRevert(QuantQueen.InvalidSender.selector);
        vm.prank(bob);
        quantQueen.claim(claimId);

        // rightful sender claims successfully
        vm.prank(alice);
        quantQueen.claim(claimId);

        // cannot claim again
        vm.expectRevert(QuantQueen.AlreadyClaimed.selector);
        vm.prank(alice);
        quantQueen.claim(claimId);
    }

    /*//////////////////////////////////////////////////////////////
                      Request validations and errors
    //////////////////////////////////////////////////////////////*/

    function test_requestClaim_requires_positive_and_sufficient_shares() public {
        // zero amount
        vm.expectRevert(QuantQueen.InvalidAmount.selector);
        vm.prank(alice);
        quantQueen.requestClaim(0);

        // insufficient shares
        vm.expectRevert(QuantQueen.InsufficientBalance.selector);
        vm.prank(alice);
        quantQueen.requestClaim(1 * ONE);

        // stake then ok
        vm.prank(alice);
        quantQueen.stake(5 * ONE);

        vm.prank(alice);
        uint256 id = quantQueen.requestClaim(2 * ONE);
        assertEq(id, 0, "first queue id = 0");
    }

    function testAddress() public{
        vm.startPrank(0x35a1C761D7c2B8bb3D6EC65b9198025C02620000);
        QuantQueen _quantQueen = new QuantQueen(
            address(token),
            treasury,
            admin, // DEFAULT_ADMIN_ROLE & PAUSER_ROLE
            bot,   // BOT_ROLE
            cutoff,
            payout,
            nextPayout
        );
        console.log(address(_quantQueen));
        vm.stopPrank();
    }
}
