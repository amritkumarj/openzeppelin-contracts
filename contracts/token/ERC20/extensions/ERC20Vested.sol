// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";

/**
 * @dev Extension of the ERC20 token contract to support token wrapping.
 *
 * Users can deposit and withdraw "underlying tokens" and receive a matching number of "wrapped tokens". This is useful
 * in conjunction with other modules. For example, combining this wrapping mechanism with {ERC20Votes} will allow the
 * wrapping of an existing "basic" ERC20 into a governance token.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Vested is ERC20 {
    IERC20 public immutable underlying;

    uint256 public unlockTime; //new code

    constructor(IERC20 underlyingToken, uint256 _unlockTime) {
        underlying = underlyingToken;
        unlockTime = _unlockTime; //new code
    }

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        try IERC20Metadata(address(underlying)).decimals() returns (uint8 value) {
            return value;
        } catch {
            return super.decimals();
        }
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        SafeERC20.safeTransferFrom(underlying, _msgSender(), address(this), amount);
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        require(block.timestamp >= unlockTime,"Vesting time has not ended"); // new code
        _burn(_msgSender(), amount);
        SafeERC20.safeTransfer(underlying, account, amount);
        return true;
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transferred by mistake. Internal
     * function that can be exposed with access control if desired.
     */
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }
}
