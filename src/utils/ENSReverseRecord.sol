// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IReverseRegistrar {
    /**
     @notice sets reverse ENS Record
     @param name the ENS record to set
     After calling this, a user has a fully configured reverse record claiming the provided name as that account's canonical name.
     */
    function setName(string memory name) external returns (bytes32);
}

/**
 @title helper contract to set reverse ens record 
 @notice sets reverse ENS record against canonical ReverseRegistrar https://docs.ens.domains/contract-api-reference/reverseregistrar.
*/
abstract contract ENSReverseRecord {

    /// @notice the ENS Reverse Registrar
    IReverseRegistrar public constant REVERSE_REGISTRAR = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    constructor(string memory name) {
        if (bytes(name).length != 0) setENSName(name);
    }

    function setENSName(string memory name) private {
        REVERSE_REGISTRAR.setName(name);
    }
}