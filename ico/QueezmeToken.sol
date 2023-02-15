//SPDX-License-Identifier: MIT

/**
 * @file QueezToken.sol
 * @author Christophe Surbier <csurbier@idevotion.fr>
 * @date created Sept. 2021
 */

 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QueezmeToken is  ERC20PresetMinterPauser, ERC20Capped , Ownable {
    constructor(uint256 _numberOfTokens) ERC20PresetMinterPauser("QzcsToken", "QZCS") ERC20Capped(1000000000*10**18)
    {
        uint256 initialSupply = _numberOfTokens * 10 ** uint256(18);  // 10000000 * 10 ** uint256(18); 
        ERC20._mint(msg.sender, initialSupply);
        
    }

       
     function _mint(
        address from,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        super._mint(from, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }

   
}
 