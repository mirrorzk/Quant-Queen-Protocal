// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract QuantQueenToken is ERC20 , Ownable {
    address public QuantQueen;

    event UpdateQuantQueen(address _oldQuantQueen, address _newQuantQueen);
    modifier onlyQuantQueen(){
        require(msg.sender == QuantQueen);
        _;
    }

    constructor() ERC20("QuantQueen", "QQB") {
        QuantQueen = msg.sender;
        emit UpdateQuantQueen(address(0), msg.sender);
    }

    function mint(address to, uint256 amount) external onlyQuantQueen{
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyQuantQueen{
        _burn(to, amount);
    }

    function setQuantQueen(address _newQuantQueen) external onlyOwner{
        require(_newQuantQueen != address(0));
        address oldQuantQueen = QuantQueen;
        QuantQueen = _newQuantQueen;
        emit UpdateQuantQueen(oldQuantQueen, _newQuantQueen);
    }


}
