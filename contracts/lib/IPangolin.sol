// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IPangolin{

    function userMap(address addr) external view returns(bool active, address referrer);

    function swap(address referrer_, uint256 amount) external;

    function bindRelationship(address referrer_) external;

    function getSuboradinateInfo() external view returns(address[] memory);
}
