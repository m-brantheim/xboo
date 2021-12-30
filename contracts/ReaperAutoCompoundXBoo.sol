// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity 0.8.9;

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

pragma solidity 0.8.9;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

pragma solidity 0.8.9;

interface IBooMirrorWorld is IERC20 {
    // Locks Boo and mints xBoo
    function enter(uint256 _amount) external;

    // Unlocks the staked + gained Boo and burns xBoo
    function leave(uint256 _share) external;

    // returns the total amount of BOO an address has in the contract including fees earned
    function BOOBalance(address _account)
        external
        view
        returns (uint256 booAmount_);

    // returns how much BOO someone gets for redeeming xBOO
    function xBOOForBOO(uint256 _xBOOAmount)
        external
        view
        returns (uint256 booAmount_);

    // returns how much xBOO someone gets for depositing BOO
    function BOOForxBOO(uint256 _booAmount)
        external
        view
        returns (uint256 xBOOAmount_);
}

interface IAceLab {
    struct PoolInfo {
        IERC20 RewardToken; // Address of reward token contract.
        uint256 RewardPerSecond; // reward token per second for this pool
        uint256 TokenPrecision; // The precision factor used for calculations, dependent on a tokens decimals
        uint256 xBooStakedAmount; // # of xboo allocated to this pool
        uint256 lastRewardTime; // Last block time that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward per share, times the pools token precision. See below.
        uint256 endTime; // end time of pool
        uint256 startTime; // start time of pool
        uint256 userLimitEndTime;
        address protocolOwnerAddress; // this address is the owner of the protocol corresponding to the reward token, used for emergency withdraw to them only
    }

    function poolInfo(uint256 _index) external returns (PoolInfo memory);

    function poolLength() external view returns (uint256);

    // View function to see pending BOOs on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Deposit tokens.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

interface IERC20Ext is IERC20 {
    function decimals() external returns (uint256);
}

// The goal of this farm is to allow a stake xBoo earn anything model
// In a flip of a traditional farm, this contract only accepts xBOO as the staking token
// Each new pool added is a new reward token, each with its own start times
// end times, and rewards per second.
// contract AceLab is Ownable {
//     using SafeERC20 for IERC20;

//     // Info of each user.
//     // struct UserInfo {
//     //     uint256 amount; // How many tokens the user has provided.
//     //     uint256 rewardDebt; // Reward debt. See explanation below.
//     // }

//     // // Info of each pool.
//     struct PoolInfo {
//         IERC20 RewardToken; // Address of reward token contract.
//         uint256 RewardPerSecond; // reward token per second for this pool
//         uint256 TokenPrecision; // The precision factor used for calculations, dependent on a tokens decimals
//         uint256 xBooStakedAmount; // # of xboo allocated to this pool
//         uint256 lastRewardTime; // Last block time that reward distribution occurs.
//         uint256 accRewardPerShare; // Accumulated reward per share, times the pools token precision. See below.
//         uint256 endTime; // end time of pool
//         uint256 startTime; // start time of pool
//         uint256 userLimitEndTime;
//         address protocolOwnerAddress; // this address is the owner of the protocol corresponding to the reward token, used for emergency withdraw to them only
//     }

//     IERC20 public immutable xboo;
//     uint256 public baseUserLimitTime = 2 days;
//     uint256 public baseUserLimit = 0;

//     // Info of each pool.
//     PoolInfo[] public poolInfo;
//     // Info of each user that stakes tokens.
//     mapping(uint256 => mapping(address => UserInfo)) public userInfo;

//     event AdminTokenRecovery(address tokenRecovered, uint256 amount);
//     event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
//     event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
//     event EmergencyWithdraw(
//         address indexed user,
//         uint256 indexed pid,
//         uint256 amount
//     );
//     event SetRewardPerSecond(uint256 _pid, uint256 _gemsPerSecond);

//     constructor(IERC20 _xboo) {
//         xboo = _xboo;
//     }

//     function poolLength() external view returns (uint256) {
//         return poolInfo.length;
//     }

//     // Return reward multiplier over the given _from to _to block.
//     function getMultiplier(
//         uint256 _from,
//         uint256 _to,
//         PoolInfo memory pool
//     ) internal pure returns (uint256) {
//         _from = _from > pool.startTime ? _from : pool.startTime;
//         if (_from > pool.endTime || _to < pool.startTime) {
//             return 0;
//         }
//         if (_to > pool.endTime) {
//             return pool.endTime - _from;
//         }
//         return _to - _from;
//     }

//     // View function to see pending BOOs on frontend.
//     function pendingReward(uint256 _pid, address _user)
//         external
//         view
//         returns (uint256)
//     {
//         PoolInfo memory pool = poolInfo[_pid];
//         UserInfo memory user = userInfo[_pid][_user];
//         uint256 accRewardPerShare = pool.accRewardPerShare;

//         if (
//             block.timestamp > pool.lastRewardTime && pool.xBooStakedAmount != 0
//         ) {
//             uint256 multiplier = getMultiplier(
//                 pool.lastRewardTime,
//                 block.timestamp,
//                 pool
//             );
//             uint256 reward = multiplier * pool.RewardPerSecond;
//             accRewardPerShare +=
//                 (reward * pool.TokenPrecision) /
//                 pool.xBooStakedAmount;
//         }
//         return
//             ((user.amount * accRewardPerShare) / pool.TokenPrecision) -
//             user.rewardDebt;
//     }

//     // Update reward variables for all pools. Be careful of gas spending!
//     function massUpdatePools() public {
//         uint256 length = poolInfo.length;
//         for (uint256 pid = 0; pid < length; ++pid) {
//             updatePool(pid);
//         }
//     }

//     // Update reward variables of the given pool to be up-to-date.
//     function updatePool(uint256 _pid) internal {
//         PoolInfo storage pool = poolInfo[_pid];
//         if (block.timestamp <= pool.lastRewardTime) {
//             return;
//         }

//         if (pool.xBooStakedAmount == 0) {
//             pool.lastRewardTime = block.timestamp;
//             return;
//         }
//         uint256 multiplier = getMultiplier(
//             pool.lastRewardTime,
//             block.timestamp,
//             pool
//         );
//         uint256 reward = multiplier * pool.RewardPerSecond;

//         pool.accRewardPerShare +=
//             (reward * pool.TokenPrecision) /
//             pool.xBooStakedAmount;
//         pool.lastRewardTime = block.timestamp;
//     }

//     // Deposit tokens.
//     function deposit(uint256 _pid, uint256 _amount) external {
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];

//         if (baseUserLimit > 0 && block.timestamp < pool.userLimitEndTime) {
//             require(
//                 user.amount + _amount <= baseUserLimit,
//                 "deposit: user has hit deposit cap"
//             );
//         }

//         updatePool(_pid);

//         uint256 pending = ((user.amount * pool.accRewardPerShare) /
//             pool.TokenPrecision) - user.rewardDebt;

//         user.amount += _amount;
//         pool.xBooStakedAmount += _amount;
//         user.rewardDebt =
//             (user.amount * pool.accRewardPerShare) /
//             pool.TokenPrecision;

//         if (pending > 0) {
//             safeTransfer(pool.RewardToken, msg.sender, pending);
//         }
//         xboo.safeTransferFrom(address(msg.sender), address(this), _amount);

//         emit Deposit(msg.sender, _pid, _amount);
//     }

//     // Withdraw tokens.
//     function withdraw(uint256 _pid, uint256 _amount) external {
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];

//         require(user.amount >= _amount, "withdraw: not good");

//         updatePool(_pid);

//         uint256 pending = ((user.amount * pool.accRewardPerShare) /
//             pool.TokenPrecision) - user.rewardDebt;

//         user.amount -= _amount;
//         pool.xBooStakedAmount -= _amount;
//         user.rewardDebt =
//             (user.amount * pool.accRewardPerShare) /
//             pool.TokenPrecision;

//         if (pending > 0) {
//             safeTransfer(pool.RewardToken, msg.sender, pending);
//         }

//         safeTransfer(xboo, address(msg.sender), _amount);

//         emit Withdraw(msg.sender, _pid, _amount);
//     }

//     // Withdraw without caring about rewards. EMERGENCY ONLY.
//     function emergencyWithdraw(uint256 _pid) external {
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];

//         uint256 oldUserAmount = user.amount;
//         pool.xBooStakedAmount -= user.amount;
//         user.amount = 0;
//         user.rewardDebt = 0;

//         xboo.safeTransfer(address(msg.sender), oldUserAmount);
//         emit EmergencyWithdraw(msg.sender, _pid, oldUserAmount);
//     }

//     // Safe erc20 transfer function, just in case if rounding error causes pool to not have enough reward tokens.
//     function safeTransfer(
//         IERC20 token,
//         address _to,
//         uint256 _amount
//     ) internal {
//         uint256 bal = token.balanceOf(address(this));
//         if (_amount > bal) {
//             token.safeTransfer(_to, bal);
//         } else {
//             token.safeTransfer(_to, _amount);
//         }
//     }

//     // Admin functions

//     function changeEndTime(uint256 _pid, uint32 addSeconds) external onlyOwner {
//         poolInfo[_pid].endTime += addSeconds;
//     }

//     function stopReward(uint256 _pid) external onlyOwner {
//         poolInfo[_pid].endTime = block.number;
//     }

//     function changePoolUserLimitEndTime(uint256 _pid, uint256 _time)
//         external
//         onlyOwner
//     {
//         poolInfo[_pid].userLimitEndTime = _time;
//     }

//     function changeUserLimit(uint256 _limit) external onlyOwner {
//         baseUserLimit = _limit;
//     }

//     function changeBaseUserLimitTime(uint256 _time) external onlyOwner {
//         baseUserLimitTime = _time;
//     }

//     function checkForToken(IERC20 _Token) private view {
//         uint256 length = poolInfo.length;
//         for (uint256 _pid = 0; _pid < length; _pid++) {
//             require(
//                 poolInfo[_pid].RewardToken != _Token,
//                 "checkForToken: reward token provided"
//             );
//         }
//     }

//     function recoverWrongTokens(address _tokenAddress) external onlyOwner {
//         require(
//             _tokenAddress != address(xboo),
//             "recoverWrongTokens: Cannot be xboo"
//         );
//         checkForToken(IERC20(_tokenAddress));

//         uint256 bal = IERC20(_tokenAddress).balanceOf(address(this));
//         IERC20(_tokenAddress).safeTransfer(address(msg.sender), bal);

//         emit AdminTokenRecovery(_tokenAddress, bal);
//     }

//     function emergencyRewardWithdraw(uint256 _pid, uint256 _amount)
//         external
//         onlyOwner
//     {
//         poolInfo[_pid].RewardToken.safeTransfer(
//             poolInfo[_pid].protocolOwnerAddress,
//             _amount
//         );
//     }

//     // Add a new token to the pool. Can only be called by the owner.
//     function add(
//         uint256 _rewardPerSecond,
//         IERC20Ext _Token,
//         uint256 _startTime,
//         uint256 _endTime,
//         address _protocolOwner
//     ) external onlyOwner {
//         checkForToken(_Token); // ensure you cant add duplicate pools

//         uint256 lastRewardTime = block.timestamp > _startTime
//             ? block.timestamp
//             : _startTime;
//         uint256 decimalsRewardToken = _Token.decimals();
//         require(decimalsRewardToken < 30, "Token has way too many decimals");
//         uint256 precision = 10**(30 - decimalsRewardToken);

//         poolInfo.push(
//             PoolInfo({
//                 RewardToken: _Token,
//                 RewardPerSecond: _rewardPerSecond,
//                 TokenPrecision: precision,
//                 xBooStakedAmount: 0,
//                 startTime: _startTime,
//                 endTime: _endTime,
//                 lastRewardTime: lastRewardTime,
//                 accRewardPerShare: 0,
//                 protocolOwnerAddress: _protocolOwner,
//                 userLimitEndTime: lastRewardTime + baseUserLimitTime
//             })
//         );
//     }

//     // Update the given pool's reward per second. Can only be called by the owner.
//     function setRewardPerSecond(uint256 _pid, uint256 _rewardPerSecond)
//         external
//         onlyOwner
//     {
//         updatePool(_pid);

//         poolInfo[_pid].RewardPerSecond = _rewardPerSecond;

//         emit SetRewardPerSecond(_pid, _rewardPerSecond);
//     }
// }

// Info of each pool.
// struct PoolInfo {
//     IERC20 RewardToken; // Address of reward token contract.
//     uint256 RewardPerSecond; // reward token per second for this pool
//     uint256 TokenPrecision; // The precision factor used for calculations, dependent on a tokens decimals
//     uint256 xBooStakedAmount; // # of xboo allocated to this pool
//     uint256 lastRewardTime; // Last block time that reward distribution occurs.
//     uint256 accRewardPerShare; // Accumulated reward per share, times the pools token precision. See below.
//     uint256 endTime; // end time of pool
//     uint256 startTime; // start time of pool
//     uint256 userLimitEndTime;
//     address protocolOwnerAddress; // this address is the owner of the protocol corresponding to the reward token, used for emergency withdraw to them only
// }

// Info of each user.
struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}

// struct UsedPool {
//     uint256 currentYield;
//     address[][] rewardTokenToWftmPaths;
// }

import "hardhat/console.sol";

pragma solidity 0.8.9;

// import "hardhat/console.sol";
// import "./Acelab.sol";

/**
 * @dev Implementation of a strategy to get yields from farming LP Pools in SpookySwap.
 * SpookySwap is an automated market maker (“AMM”) that allows two tokens to be exchanged on Fantom's Opera Network.
 *
 * This strategy deposits whatever funds it receives from the vault into the selected masterChef pool.
 * rewards from providing liquidity are farmed every few minutes, sold and split 50/50.
 * The corresponding pair of assets are bought and more liquidity is added to the masterChef pool.
 *
 * Expect the amount of LP tokens you have to grow over time while you have assets deposit
 */
contract ReaperAutoCompoundXBoo is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Tokens Used:
     * {wftm} - Required for liquidity routing when doing swaps.
     * {stakingToken} - Token generated by staking our funds.
     * {rewardToken} - LP Token that the strategy maximizes.
     */
    address public wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public stakingToken;
    address public rewardToken;

    /**
     * @dev Third Party Contracts:
     * {uniRouter} - the uniRouter for target DEX
     * {aceLabAddress} - Address to AceLab
     * {aceLab} - The AceLab contract
     * {currentPoolId} - the currently selected AceLab pool id
     */
    address public uniRouter;
    address public aceLabAddress;
    IAceLab public aceLab;
    uint8 public currentPoolId;

    /**
     * @dev Reaper Contracts:
     * {treasury} - Address of the Reaper treasury
     * {vault} - Address of the vault that controls the strategy's funds.
     */
    address public treasury;
    address public vault;

    /**
     * @dev Distribution of fees earned. This allocations relative to the % implemented on
     * Current implementation separates 5% for fees. Can be changed through the constructor
     * Inputs in constructor should be ratios between the Fee and Max Fee, divisble into percents by 10000
     *
     * {callFee} - Percent of the totalFee reserved for the harvester (1000 = 10% of total fee: 0.5% by default)
     * {treasuryFee} - Percent of the totalFee taken by maintainers of the software (9000 = 90% of total fee: 4.5% by default)
     * {securityFee} - Fee taxed when a user withdraws funds. Taken to prevent flash deposit/harvest attacks.
     * These funds are redistributed to stakers in the pool.
     *
     * {totalFee} - divided by 10,000 to determine the % fee. Set to 5% by default and
     * lowered as necessary to provide users with the most competitive APY.
     *
     * {MAX_FEE} - Maximum fee allowed by the strategy. Hard-capped at 5%.
     * {PERCENT_DIVISOR} - Constant used to safely calculate the correct percentages.
     */

    uint256 public callFee = 1000;
    uint256 public treasuryFee = 9000;
    uint256 public securityFee = 10;
    uint256 public totalFee = 450;
    uint256 public constant MAX_FEE = 500;
    uint256 public constant PERCENT_DIVISOR = 10000;

    /**
     * @dev Routes we take to swap tokens
     * {wftmToRewardTokenRoute} - Route we take to get from {wftm} into {rewardToken}.
     * {poolTokenToWftmRoute} - Route we take to get from {pool reward token} into {wftm}.
     */
    address[] public wftmToRewardTokenRoute;

    uint8[] currentlyUsedPools;
    mapping(uint8 => uint256) poolYield;
    mapping(uint8 => bool) hasAllocatedToPool;
    mapping(uint8 => address[]) poolRewardToWftmPaths;
    mapping(uint8 => uint256) poolBalance;
    uint8 constant WFTM_POOL_ID = 2;
    uint256 totalPoolBalance = 0;

    /**
     * {StratHarvest} Event that is fired each time someone harvests the strat.
     * {TotalFeeUpdated} Event that is fired each time the total fee is updated.
     * {CallFeeUpdated} Event that is fired each time the call fee is updated.
     */
    event StratHarvest(address indexed harvester);
    event TotalFeeUpdated(uint256 newFee);
    event CallFeeUpdated(uint256 newCallFee, uint256 newTreasuryFee);

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    constructor(
        address _uniRouter,
        address _aceLabAddress,
        address _rewardToken,
        address _stakingToken,
        address _vault,
        address _treasury
    ) public {
        uniRouter = _uniRouter;
        aceLabAddress = _aceLabAddress;
        aceLab = IAceLab(aceLabAddress);
        rewardToken = _rewardToken;
        stakingToken = _stakingToken;
        vault = _vault;
        treasury = _treasury;
        wftmToRewardTokenRoute = [wftm, rewardToken];
        currentPoolId = WFTM_POOL_ID;

        giveAllowances();
    }

    function addUsedPool(uint8 _poolId, address[] memory _poolRewardToWftmPaths)
        external
    {
        currentlyUsedPools.push(_poolId);
        poolRewardToWftmPaths[_poolId] = _poolRewardToWftmPaths;
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {rewardToken} into xBoo (BooMirrorWorld) to farm {stakingToken}
     */
    function deposit() public whenNotPaused {
        uint256 tokenBal = IERC20(rewardToken).balanceOf(address(this));

        if (tokenBal > 0) {
            IBooMirrorWorld(stakingToken).enter(tokenBal);
            uint256 stakingTokenBal = IERC20(stakingToken).balanceOf(
                address(this)
            );
            aceLab.deposit(currentPoolId, stakingTokenBal);
            totalPoolBalance = totalPoolBalance.add(stakingTokenBal);
            poolBalance[currentPoolId] = poolBalance[currentPoolId].add(
                stakingTokenBal
            );
        }
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {rewardToken} from the masterChef.
     * The available {rewardToken} minus fees is returned to the vault.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 tokenBal = IERC20(rewardToken).balanceOf(address(this));

        if (tokenBal < _amount) {
            for (
                uint256 index = 0;
                index < currentlyUsedPools.length;
                index++
            ) {
                uint8 poolId = currentlyUsedPools[index];
                uint256 currentPoolBalance = poolBalance[poolId];
                if (currentPoolBalance > 0) {
                    uint256 remainingAmount = _amount - tokenBal;
                    uint256 withdrawAmount;
                    if (remainingAmount > currentPoolBalance) {
                        withdrawAmount = currentPoolBalance;
                    } else {
                        withdrawAmount = remainingAmount;
                    }
                    aceLab.withdraw(poolId, withdrawAmount);
                    uint256 stakingTokenBal = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    IBooMirrorWorld(stakingToken).leave(stakingTokenBal);
                    totalPoolBalance = totalPoolBalance.sub(stakingTokenBal);
                    poolBalance[poolId] = poolBalance[poolId].sub(
                        stakingTokenBal
                    );
                    tokenBal = IERC20(rewardToken).balanceOf(address(this));
                    if (tokenBal >= _amount) {
                        break;
                    }
                }
            }
        }

        if (tokenBal > _amount) {
            tokenBal = _amount;
        }
        uint256 withdrawFee = tokenBal.mul(securityFee).div(PERCENT_DIVISOR);
        IERC20(rewardToken).safeTransfer(vault, tokenBal.sub(withdrawFee));
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. It claims rewards from the masterChef.
     * 2. It charges the system fees to simplify the split.
     * 3. It swaps the {rewardToken} token for {lpToken0} & {lpToken1}
     * 4. Adds more liquidity to the pool.
     * 5. It deposits the new LP tokens.
     */
    function harvest() external whenNotPaused {
        console.log("harvest()");
        require(!Address.isContract(msg.sender), "!contract");
        _collectRewardsAndEstimateYield();
        _chargeFees();
        _compoundRewards();
        _rebalance();
        emit StratHarvest(msg.sender);
    }

    function _rebalance() internal {
        console.log("rebalance()");
        uint256 stakingBal = IERC20(stakingToken).balanceOf(address(this));
        while (stakingBal > 0) {
            uint256 bestYield = 0;
            uint8 bestYieldPoolId = WFTM_POOL_ID;
            uint256 bestYieldIndex = 0;
            for (
                uint256 index = 0;
                index < currentlyUsedPools.length;
                index++
            ) {
                uint8 poolId = currentlyUsedPools[index];
                if (hasAllocatedToPool[poolId] == false) {
                    uint256 currentPoolYield = poolYield[poolId];
                    if (currentPoolYield > bestYield) {
                        bestYield = currentPoolYield;
                        bestYieldPoolId = poolId;
                        bestYieldIndex = index;
                    }
                }
            }
            uint256 poolDepositAmount = stakingBal;
            IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(bestYieldPoolId);
            bool isWFTM = address(poolInfo.RewardToken) == wftm;

            if (!isWFTM && poolDepositAmount > poolInfo.xBooStakedAmount / 5) {
                poolDepositAmount = poolInfo.xBooStakedAmount / 5;
            }
            aceLab.deposit(bestYieldPoolId, poolDepositAmount);
            totalPoolBalance = totalPoolBalance.add(poolDepositAmount);
            hasAllocatedToPool[bestYieldPoolId] = true;
            stakingBal = IERC20(stakingToken).balanceOf(address(this));
            currentPoolId = bestYieldPoolId;
        }
    }

    function _compoundRewards() internal {
        uint256 wftmBal = IERC20(wftm).balanceOf(address(this));
        if (wftmBal > 0) {
            IUniswapRouterETH(uniRouter)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    wftmBal,
                    0,
                    wftmToRewardTokenRoute,
                    address(this),
                    block.timestamp.add(600)
                );
            uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
            IBooMirrorWorld(stakingToken).enter(rewardBal);
        }
    }

    function _collectRewardsAndEstimateYield() internal {
        console.log("_collectRewardsAndEstimateYield()");
        uint256 nrOfUsedPools = currentlyUsedPools.length;
        for (uint256 index = 0; index < nrOfUsedPools; index++) {
            uint8 poolId = currentlyUsedPools[index];
            // uint256 pendingReward = aceLab.pendingReward(poolId, address(this));
            aceLab.withdraw(poolId, 0);
            _swapRewardToWftm(poolId);
            _setEstimatedYield(poolId);
        }
    }

    function _swapRewardToWftm(uint8 _poolId) internal {
        console.log("_swapRewardToWftm()");
        address[] memory rewardToWftmPaths = poolRewardToWftmPaths[_poolId];
        IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(_poolId);
        uint256 poolRewardTokenBal = poolInfo.RewardToken.balanceOf(
            address(this)
        );
        if (poolRewardTokenBal > 0) {
            // Default to support empty or incomplete path array
            if (rewardToWftmPaths.length < 2) {
                rewardToWftmPaths[0] = address(poolInfo.RewardToken);
                rewardToWftmPaths[1] = wftm;
            }
            IUniswapRouterETH(uniRouter)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    poolRewardTokenBal,
                    0,
                    rewardToWftmPaths,
                    address(this),
                    block.timestamp.add(600)
                );
        }
    }

    function _setEstimatedYield(uint8 _poolId) internal {
        console.log("_setEstimatedYield()");
        IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(_poolId);
        uint256 multiplier = _getMultiplier(
            block.timestamp,
            block.timestamp + 1 days,
            poolInfo
        );
        // console.log("---------------------------------");
        // console.log("RewardToken: ", address(pool.RewardToken));
        // console.log("RewardsPerSecond: ", pool.RewardPerSecond);
        // console.log("multiplier: ", multiplier);
        uint256 totalTokens = multiplier * poolInfo.RewardPerSecond;
        if (address(poolInfo.RewardToken) == wftm) {
            // console.log("is wftm");
            uint256 wftmYield = (1 ether * totalTokens) /
                poolInfo.xBooStakedAmount;
            console.log("WFTM: ", wftmYield);
            poolYield[_poolId] = wftmYield;
        } else {
            address[] memory path = new address[](2);
            path[0] = address(poolInfo.RewardToken);
            path[1] = wftm;
            uint256 wftmTotalPoolYield = IUniswapRouterETH(uniRouter)
                .getAmountsOut(totalTokens, path)[1];
            uint256 wftmYield = (1 ether * wftmTotalPoolYield) /
                poolInfo.xBooStakedAmount;
            console.log(
                IERC20Metadata(address(poolInfo.RewardToken)).symbol(),
                ": ",
                wftmYield
            );
            poolYield[_poolId] = wftmYield;
        }
        hasAllocatedToPool[_poolId] = false;
    }

    // Return reward multiplier over the given _from to _to block.
    function _getMultiplier(
        uint256 _from,
        uint256 _to,
        IAceLab.PoolInfo memory pool
    ) internal pure returns (uint256) {
        _from = _from > pool.startTime ? _from : pool.startTime;
        if (_from > pool.endTime || _to < pool.startTime) {
            return 0;
        }
        if (_to > pool.endTime) {
            return pool.endTime - _from;
        }
        return _to - _from;
    }

    /**
     * @dev Takes out fees from the rewards. Set by constructor
     * callFeeToUser is set as a percentage of the fee,
     * as is treasuryFeeToVault
     */
    function _chargeFees() internal {
        console.log("_chargeFees()");
        if (totalFee != 0) {
            uint256 wftmBal = IERC20(wftm).balanceOf(address(this));
            uint256 wftmFee = wftmBal.mul(totalFee).div(PERCENT_DIVISOR);

            uint256 callFeeToUser = wftmFee.mul(callFee).div(PERCENT_DIVISOR);
            IERC20(wftm).safeTransfer(msg.sender, callFeeToUser);

            uint256 treasuryFeeToVault = wftmFee.mul(treasuryFee).div(
                PERCENT_DIVISOR
            );
            IERC20(wftm).safeTransfer(treasury, treasuryFeeToVault);
        }
    }

    /**
     * @dev Function to calculate the total underlaying {rewardToken} held by the strat.
     * It takes into account both the funds in hand, as the funds allocated in the masterChef.
     */
    function balanceOf() public view returns (uint256) {
        console.log("balanceOf()");
        console.log("balanceOfRewardToken(): ", balanceOfRewardToken());
        console.log("balanceOfStakingToken(): ", balanceOfStakingToken());
        console.log("balanceOfPool(): ", balanceOfPool());
        uint256 balance = balanceOfRewardToken().add(
            balanceOfStakingToken().add(balanceOfPool())
        );
        console.log(balance);
        return balance;
    }

    /**
     * @dev It calculates how much {rewardToken} the contract holds.
     */
    function balanceOfRewardToken() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this));
    }

    /**
     * @dev It calculates how much {rewardToken} the contract has staked.
     */
    function balanceOfStakingToken() public view returns (uint256) {
        return IBooMirrorWorld(stakingToken).BOOBalance(address(this));
    }

    /**
     * @dev It calculates how much {rewardToken} the strategy has allocated in the AceLab pools
     */
    function balanceOfPool() public view returns (uint256) {
        return IBooMirrorWorld(stakingToken).xBOOForBOO(totalPoolBalance);
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        // IMasterChef(masterChef).emergencyWithdraw(poolId);

        uint256 tokenBal = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).transfer(vault, tokenBal);
    }

    /**
     * @dev Pauses deposits. Withdraws all funds from the masterChef, leaving rewards behind
     */
    function panic() public onlyOwner {
        pause();
        // IMasterChef(masterChef).withdraw(poolId, balanceOfPool());
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public onlyOwner {
        _pause();
        removeAllowances();
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external onlyOwner {
        _unpause();

        giveAllowances();

        deposit();
    }

    function giveAllowances() internal {
        // Give xBOO permission to use Boo
        IERC20(rewardToken).safeApprove(stakingToken, type(uint256).max);
        // Give xBoo contract permission to stake xBoo
        IERC20(stakingToken).safeApprove(aceLabAddress, type(uint256).max);
    }

    function removeAllowances() internal {
        // IERC20(rewardToken).safeApprove(masterChef, 0);
    }

    /**
     * @dev updates the total fee, capped at 5%
     */
    function updateTotalFee(uint256 _totalFee)
        external
        onlyOwner
        returns (bool)
    {
        require(_totalFee <= MAX_FEE, "Fee Too High");
        totalFee = _totalFee;
        emit TotalFeeUpdated(totalFee);
        return true;
    }

    /**
     * @dev updates the call fee and adjusts the treasury fee to cover the difference
     */
    function updateCallFee(uint256 _callFee) external onlyOwner returns (bool) {
        callFee = _callFee;
        treasuryFee = PERCENT_DIVISOR.sub(callFee);
        emit CallFeeUpdated(callFee, treasuryFee);
        return true;
    }

    function updateTreasury(address newTreasury)
        external
        onlyOwner
        returns (bool)
    {
        treasury = newTreasury;
        return true;
    }
}
