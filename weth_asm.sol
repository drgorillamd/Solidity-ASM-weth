pragma solidity 0.8.7;

contract test {
    
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    
    fallback() external payable {
        deposit();
    }
    
    function deposit() public payable {
        assembly {
            mstore(0x0, origin()) //msg.sender
            mstore(0x20, 3) //slot3: balanceOf
            let hash := keccak256(0x0, 64) //from 0, for 2 bytes
            let new_bal := add(callvalue(), sload(hash))
            sstore(hash, new_bal)
        }
    }

    function withdraw(uint wad) public {
        assembly {
            // load balanceOf key
            mstore(0x0, origin()) //msg.sender
            mstore(0x20, 3) //slot3: balanceOf
            let hash := keccak256(0x0, 64) //from 0, for 2 bytes
            
            // load current balance and wad
            let bal := sload(hash)
            let val := calldataload(4)
            
            //require(balanceOf[msg.sender] >= wad);
            if lt(bal, val) { revert(0,0) }
            
            //balanceOf[msg.sender] -= wad;
            sstore(hash, sub(bal, val))
            
            let ret := call (22000, 
            origin(),
            val, 
            0, // input
            0x0, // input size = 4 bytes
            0, // output stored at input location, save space
            0x0 // output size = 0 bytes
            )

        }
    }
    
    function totalSupply() public view returns (uint) {
        assembly {
            let bal := selfbalance()
            mstore(0x20, bal)
            return(0x20, 32)
        }
    }

    function approve(address guy, uint wad) public returns (bool) {
        assembly {
            let spender := calldataload(4)
            let val := calldataload(36)
            
            mstore(0x0, origin()) //msg.sender
            mstore(0x20, 4) //slot4: allowance
            let hash_first_level := keccak256(0x0, 64) //from 0, for 2 bytes

            mstore(0x0, spender)
            mstore(0x20, hash_first_level)
            let hash_sec := keccak256(0x0, 64)
            
            sstore(hash_sec, val)
            mstore(0x0, 1)
            return(0x0, 1)
        }
    }

    function transfer(address dst, uint wad) public returns (bool) {
        assembly {
            let receiver := calldataload(4)
            let val := calldataload(36)
            
            // balanceOf[src]
            mstore(0x0, origin()) //msg.sender
            mstore(0x20, 3) //slot3: balanceOf
            let hash_sender := keccak256(0x0, 64) //from 0, for 2 bytes
            let bal_sender := sload(hash_sender)
            
            // balance < wad ?
            if lt(bal_sender, val) { revert(0,0) }
            
            sstore(hash_sender, sub(bal_sender, val))
            
            mstore(0x0, receiver)
            mstore(0x20, 3) //slot3: balanceOf
            let hash_receiver := keccak256(0x0, 64) //from 0, for 2 bytes
            sstore(hash_receiver, add(sload(hash_receiver), val))
            
            mstore(0x0, 1)
            return(0x0, 1)
        }
    }
    
    function transferFrom(address src, address dst, uint wad) public returns(bool) {
        assembly {
            let sender := calldataload(4)
            let receiver := calldataload(36)
            let val := calldataload(68)
            
            // balanceOf[src]
            mstore(0x0, sender) //msg.sender
            mstore(0x20, 3) //slot3: balanceOf
            let hash_sender := keccak256(0x0, 64) //from 0, for 2 bytes
            let bal_sender := sload(hash_sender)
            
            // balance < wad ?
            if lt(bal_sender, val) { revert(0,0) }
            
            // src != msg.sender ?
            if lt(eq(sender, origin()), 1) {
                mstore(0x0, origin()) //msg.sender
                mstore(0x20, 4) //slot4: allowance
                let hash_first_level := keccak256(0x0, 64) //from 0, for 2 bytes
    
                mstore(0x0, sender)
                mstore(0x20, hash_first_level)
                let hash_sec := keccak256(0x0, 64)
                
                // allowance[src][msg.sender] != type(uint).max ?
                if lt(sload(hash_sec), not(0x0)) {
                    // allowance[src][msg.sender] < wad ?
                    if lt(sload(hash_sec), val) { revert(0,0) }
                    
                    // allowance[src][msg.sender] -= val
                    sstore(hash_sec, sub(sload(hash_sec), val))
                }
            }
            
            sstore(hash_sender, sub(bal_sender, val))
            
            mstore(0x0, receiver) 
            mstore(0x20, 3) //slot3: balanceOf
            let hash_receiver := keccak256(0x0, 64) //from 0, for 2 bytes
            sstore(hash_receiver, add(sload(hash_receiver), val))
            
            mstore(0x0, 1)
            return(0x0, 1)
        }
    }

}
