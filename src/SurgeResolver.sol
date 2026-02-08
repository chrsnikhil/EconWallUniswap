// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @notice Custom error for CCIP-Read offchain lookup
error OffchainLookup(
    address sender,
    string[] urls,
    bytes callData,
    bytes4 callbackFunction,
    bytes extraData
);

/**
 * @title SurgeResolver
 * @notice ENS Resolver implementing CCIP-Read (EIP-3668) for offchain data
 * @dev Deploy on Sepolia. Points to your Next.js Gateway API.
 */
contract SurgeResolver {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @notice Gateway URL - your Next.js API endpoint
    string public gatewayUrl;
    
    /// @notice Address whose signature is trusted (server wallet)
    address public signer;
    
    /// @notice Owner for admin functions
    address public owner;

    event SignerUpdated(address indexed oldSigner, address indexed newSigner);
    event GatewayUpdated(string oldUrl, string newUrl);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(string memory _gatewayUrl, address _signer) {
        gatewayUrl = _gatewayUrl;
        signer = _signer;
        owner = msg.sender;
    }

    /**
     * @notice Standard ENS resolve function
     * @dev Reverts with OffchainLookup to trigger CCIP-Read
     */
    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = gatewayUrl;

        bytes memory callData = abi.encode(name, data, msg.sender);

        revert OffchainLookup(
            address(this),
            urls,
            callData,
            this.resolveWithProof.selector,
            data
        );
    }

    /**
     * @notice Callback after gateway response
     * @dev Verifies signature and returns result
     */
    function resolveWithProof(
        bytes calldata response,
        bytes calldata /* extraData */
    ) external view returns (bytes memory) {
        (bytes memory sig, bytes memory result) = abi.decode(response, (bytes, bytes));

        bytes32 messageHash = keccak256(result);
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address recovered = ECDSA.recover(ethSignedHash, sig);
        
        require(recovered == signer, "Invalid signature");

        return result;
    }

    /**
     * @notice EIP-165 interface detection
     */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        // IExtendedResolver interface ID
        return interfaceID == 0x9061b923;
    }

    // ============ Admin Functions ============

    function setSigner(address _signer) external onlyOwner {
        emit SignerUpdated(signer, _signer);
        signer = _signer;
    }

    function setGatewayUrl(string memory _url) external onlyOwner {
        emit GatewayUpdated(gatewayUrl, _url);
        gatewayUrl = _url;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }
}
