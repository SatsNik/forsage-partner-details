/**
 *Submitted for verification at testnet.bscscan.com on 2024-11-29
*/

/**
 *Submitted for verification at testnet.bscscan.com on 2024-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartMatrixForsage {
    function users(address) external view returns (
        uint256 id,
        address referrer,
        uint256 partnersCount,
        uint256 registrationTime
    );
    function idToAddress(uint256) external view returns (address);
    function userIds(uint256) external view returns (address);
    function lastUserId() external view returns (uint256);
    function LAST_LEVEL() external view returns (uint8);
    function allDirectPartners(address, uint8, uint8, address) external view returns (bool);
    function usersActiveX3Levels(address userAddress, uint8 level) external view returns (bool);
    function usersActiveX6Levels(address userAddress, uint8 level) external view returns (bool);
}

contract SmartMatrixViewHelper {
    ISmartMatrixForsage public immutable mainContract;

    constructor(address _mainContract) {
        require(_mainContract != address(0), "Invalid main contract address");
        mainContract = ISmartMatrixForsage(_mainContract);
    }

    struct PartnerDetails {
        uint256 partnerId;
        address partnerAddress;
        uint256 registrationTime;
        uint8 highestX3Level;
        uint8 highestX6Level;
    }

    function getDirectPartnerDetails(uint256 userId) external view returns (PartnerDetails[] memory) {
        require(userId > 0 && userId < mainContract.lastUserId(), "Invalid user ID");
        address userAddress = mainContract.idToAddress(userId);
        require(userAddress != address(0), "User does not exist");

        uint8 LAST_LEVEL = mainContract.LAST_LEVEL();
        uint256 totalPartners = mainContract.lastUserId();
        PartnerDetails[] memory directPartners = new PartnerDetails[](totalPartners);
        uint256 partnerCount = 0;

        for (uint256 i = 1; i < totalPartners; i++) {
            address partnerAddress = mainContract.userIds(i);
            bool isDirect = false;

            // Check if partner is direct in either matrix
            for (uint8 level = 1; level <= LAST_LEVEL; level++) {
                if (mainContract.allDirectPartners(userAddress, 1, level, partnerAddress) ||
                    mainContract.allDirectPartners(userAddress, 2, level, partnerAddress)) {
                    isDirect = true;
                    break;
                }
            }

            if (isDirect) {
                (uint256 partnerId, , , uint256 registrationTime) = mainContract.users(partnerAddress);
                
                uint8 highestX3Level = getHighestActiveLevel(partnerAddress, 1);
                uint8 highestX6Level = getHighestActiveLevel(partnerAddress, 2);

                directPartners[partnerCount] = PartnerDetails({
                    partnerId: partnerId,
                    partnerAddress: partnerAddress,

                    registrationTime: registrationTime,
                    
                    highestX3Level: highestX3Level,
                    highestX6Level: highestX6Level
                });
                partnerCount++;
            }
        }

        // Resize the array to fit actual number of direct partners found
        bytes memory resultEncoded = abi.encode(directPartners);
        assembly {
            mstore(add(resultEncoded, 0x40), partnerCount)
        }
        
        return abi.decode(resultEncoded, (PartnerDetails[]));
    }

    function getHighestActiveLevel(address partnerAddress, uint8 matrix) internal view returns (uint8) {
        uint8 highest = 0;
        uint8 LAST_LEVEL = mainContract.LAST_LEVEL();

        for (uint8 level = 1; level <= LAST_LEVEL; level++) {

            bool isActive = (matrix == 1)
                ? mainContract.usersActiveX3Levels(partnerAddress, level)

                : mainContract.usersActiveX6Levels(partnerAddress, level);

            if (isActive) {
                highest = level;

            }
        }

        return highest;
    }
}
