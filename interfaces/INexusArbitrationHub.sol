// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface INexusArbitrationHub {
    function createDisputeCase(address seller, address arbiter, bytes32 evidenceHash) external payable returns (uint256);
    function resolveDisputeBuyer(uint256 caseId) external;
    function resolveDisputeSeller(uint256 caseId) external;
}
