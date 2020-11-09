pragma solidity ^0.5.0;

contract Validators {

    /**
    * @dev The staking for validation
    */
    struct Validator {
        uint256 status;
        uint256 deactivatedTime;
        uint256 deactivatedEpoch;

        uint256 receivedStake;
        uint256 createdEpoch;
        uint256 createdTime;

        address auth;
    }

    mapping(uint256 => Validator) public getValidator;
    mapping(address => uint256) public getValidatorID;

    function createValidator(bytes calldata pubkey) external payable {
        require(msg.value >= minSelfStake(), "insufficient self-stake");
        _createValidator(msg.sender, pubkey);
        _stake(msg.sender, lastValidatorID, msg.value);
    }

    function _createValidator(address auth, bytes memory pubkey) internal {
        uint256 validatorID = ++lastValidatorID;
        _rawCreateValidator(auth, validatorID, pubkey, OK_STATUS, currentEpoch(), now, 0, 0);
    }

    function _rawCreateValidator(address auth, uint256 validatorID,  bytes memory pubkey, uint256 status, uint256 createdEpoch, uint256 createdTime, uint256 deactivatedEpoch, uint256 deactivatedTime) internal {
        require(getValidatorID[auth] == 0, "validator already exists");
        getValidatorID[auth] = validatorID;
        getValidator[validatorID].status = status;
        getValidator[validatorID].createdEpoch = createdEpoch;
        getValidator[validatorID].createdTime = createdTime;
        getValidator[validatorID].deactivatedTime = deactivatedTime;
        getValidator[validatorID].deactivatedEpoch = deactivatedEpoch;
        getValidator[validatorID].auth = auth;
        getValidatorPubkey[validatorID] = pubkey;
    }

    function _deactivateValidator(uint256 validatorID, uint256 status) external {
        require(msg.sender == address(0), "not callable");
        require(status != OK_STATUS, "wrong status");

        _setValidatorDeactivated(validatorID, status);
        _syncValidator(validatorID);
    }

    function _setValidatorDeactivated(uint256 validatorID, uint256 status) internal {
        // status as a number is proportional to severity
        if (status > getValidator[validatorID].status) {
            getValidator[validatorID].status = status;
            if (getValidator[validatorID].deactivatedEpoch == 0) {
                getValidator[validatorID].deactivatedTime = now;
                getValidator[validatorID].deactivatedEpoch = currentEpoch();
            }
        }
    }

    function _validatorExists(uint256 validatorID) view internal returns (bool) {
        return getValidator[validatorID].createdTime != 0;
    }



}
