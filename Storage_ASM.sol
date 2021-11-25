//SPDX-licence: MIT
pragma solidity "0.8.7";

/// @dev interface to the Storage fallback ASM contract (to get the returned values) + test env in Remix
contract Caller {

    address callee;
    
    constructor() {
        callee = address(new Storage_ASM());
    }
    
    /// @dev static call to emulate call to a view function (fallback cannot be view)
    function call_view() external view returns(uint256 ret) {
        (bool success, bytes memory data) = callee.staticcall(new bytes(0)); //bypass the "this function might change state" error
        require(success, "not success");
        
        assembly {
            ret := mload(add(data, 0x20)) //bytes to uint
        }
    }

    function call_set(uint256 _val) external {
        (bool success, ) = callee.call(abi.encode(_val)); //no function selector
        require(success, "not success");
    }
}

/// @dev the store & retrieve classic example, in assembly, using fallback as unique point of entry
contract Storage_ASM{

    uint256 number=42069; //0xA455

    /// @dev calldata size 
    fallback(bytes calldata args) external returns(bytes memory returned) { //only fallback def with return accepted in solc
        assembly {

            //retrieve() if calldata is empty:
            if iszero(calldatasize()) {
                // ret = new bytes(32)
                returned := mload(0x40)

                // new "memory end"
                mstore(0x40, add(returned, 64))

                // store bytes length (uint only->32)
                mstore(returned, 32)

                // value = number
                let value := sload(number.slot)

                // store it as only elt in the bytes returned
                mstore(add(returned, 32), value)
            }

            //store(new_val) is calldataz non-empty:
            if gt(calldatasize(), 0) {
                //new_val is the only data worth in calldata
                let new_val := calldataload(0)

                // number = new_val, will cast as uint256
                sstore(number.slot, new_val)
            }

        }
    }
}
