// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DegenToken is ERC20, Ownable {
    uint256 public totalItems; // Variable to store the total number of items

    constructor() ERC20("Degen", "DGN")  {
        totalItems = 0; // Initialize totalItems to 0
    }

    struct Item {
        uint256 cost;
        string name;
    }

    // Mapping to store items and their corresponding costs
    mapping(uint256 => Item) public items;

    // Mapping to store player inventories
    mapping(bytes32 => uint256) public playerInventory;

    function initializeItems() external onlyOwner {
        // Initialize items here
        addItem(1, 10, "1x Saint Quartz");
        addItem(2, 80, "10x Saint Quartz");
        addItem(3, 5, "1x Summon Ticket");
        addItem(4, 40, "10x Summon Ticket");
        addItem(5, 5, "1x Lotto Ticket");
        addItem(6, 40, "10x Lotto Ticket");
        addItem(7, 100, "1x Holy Grail");
        addItem(8, 275, "3x Holy Grail");
        addItem(9, 25, "Material Bundle #1");
        addItem(10, 25, "Material Bundle #2");
        addItem(11, 25, "Material Bundle #3");
        addItem(12, 25, "EXP Bundle #1");
        addItem(13, 25, "EXP Bundle #2");
        addItem(14, 25, "EXP Bundle #3");
        addItem(15, 5, "1x Golden Apple");
        addItem(16, 3, "1x Silver Apple");
        addItem(17, 1, "1x Bronze Apple");
        addItem(18, 40, "10x Golden Apple");
        addItem(19, 25, "10x Silver Apple");
        addItem(20, 8, "10x Bronze Apple");
    }

    modifier validRecipient(address recipient) {
        require(recipient != address(0), "ERROR: Invalid recipient address");
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "ERROR: Amount must be greater than zero");
        _;
    }

    modifier hasSufficientBalance(uint256 amount) {
        require(balanceOf(msg.sender) >= amount, "ERROR: Account has insufficient balance");
        _;
    }

    function mintTokens(address to, uint256 amount) public onlyOwner validRecipient(to) validAmount(amount) {
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) override public validRecipient(recipient) validAmount(amount) hasSufficientBalance(amount) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function burnTokens(uint256 amount) public validAmount(amount) hasSufficientBalance(amount) {
        _burn(msg.sender, amount);
    }

    function redeemTokens(uint256 choice) public validAmount(choice) hasSufficientBalance(choice) returns (bool) {
        require(items[choice].cost > 0, "ERROR: Invalid item choice");
        uint256 tokens = items[choice].cost;
        string memory itemName = items[choice].name;

        addToInventory(msg.sender, choice, 1);

        emit redeemItems(msg.sender, choice, itemName);
        _burn(msg.sender, tokens);
        return true;
    }
    
    event redeemItems(address indexed player, uint256 choice, string itemName);

    function addItem(uint256 itemId, uint256 cost, string memory name) public onlyOwner {
        items[itemId] = Item(cost, name);
        totalItems++; // Increment totalItems when adding a new item
    }

    // Function to get the total number of items
    function getTotalItems() public view returns (uint256) {
        return totalItems;
    }

    function getItem(uint256 index) public view returns (Item memory) {
        return items[index];
    }

    function updateItemCost(uint256 itemId, uint256 newCost) public onlyOwner {
        require(items[itemId].cost > 0, "ERROR: Item does not exist");
        items[itemId].cost = newCost;
    }

    function removeItem(uint256 itemId) public onlyOwner {
        require(items[itemId].cost > 0, "ERROR: Item does not exist");
        delete items[itemId];
        totalItems--;
    }

    function displayItems() public view returns (string memory) {
        string memory itemList;
        for (uint256 i = 1; i <= totalItems; i++) {
            if (items[i].cost > 0) {
                itemList = string(abi.encodePacked(itemList, "\n", uint2str(i), ": ", items[i].name, " for ", uint2str(items[i].cost), " Tokens"));
            }
        }
        return itemList;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

    function balanceOf(address account) public view override returns (uint256) {
        require(account != address(0), "ERROR: Invalid address");
        return super.balanceOf(account);
    }

    function pronounceOwnership(address newOwner) external {
        require(owner() == address(0), "ERROR: Ownership already pronounced");
        _transferOwnership(newOwner);
    }

    // Function to add to inventory
    function addToInventory(address player, uint256 itemId, uint256 quantity) public onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(player, itemId));
        playerInventory[key] += quantity;
    }

    // Function to get player inventory
    function getPlayerItem(address player, uint256 itemId) public view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(player, itemId));
        return playerInventory[key];
    }

    // Function to get player's entire inventory with names and quantities
    function getPlayerInventory(address player) public view returns (string[] memory, uint256[] memory) {
        string[] memory itemNames = new string[](totalItems);
        uint256[] memory itemQuantities = new uint256[](totalItems);

        for (uint256 itemId = 1; itemId <= totalItems; itemId++) {
            bytes32 key = keccak256(abi.encodePacked(player, itemId));
            itemQuantities[itemId - 1] = playerInventory[key];
            itemNames[itemId - 1] = items[itemId].name;
        }

        return (itemNames, itemQuantities);
    }

        // Function to get player's inventory as a formatted string
    function getPlayerInventoryString(address player) public view returns (string memory) {
        string[] memory itemNames;
        uint256[] memory itemQuantities;

        (itemNames, itemQuantities) = getPlayerInventory(player);

        string memory inventoryString = "Player Inventory:\n";
        for (uint256 i = 0; i < itemNames.length; i++) {
            inventoryString = string(abi.encodePacked(inventoryString, itemNames[i], ": ", uint2str(itemQuantities[i]), "\n"));
        }

        return inventoryString;
    }
}
