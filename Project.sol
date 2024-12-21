// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Interface for ERC721 token (NFT standard) for educational assets
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// Cross-Chain DEX contract for Educational Assets
contract CrossChainDEX {

    struct Listing {
        address seller;
        uint256 price;
        uint256 tokenId;
        address assetContract; // ERC721 contract address (educational asset token)
    }

    // Mapping from listing ID to Listing
    mapping(uint256 => Listing) public listings;
    uint256 public listingCount;

    // Event for new listing
    event AssetListed(
        uint256 indexed listingId,
        address indexed seller,
        uint256 price,
        uint256 tokenId,
        address assetContract
    );

    // Event for asset purchased
    event AssetPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 tokenId
    );

    // Event for listing canceled
    event ListingCanceled(
        uint256 indexed listingId,
        address indexed seller
    );

    // Modifier to check if the sender is the seller of the listing
    modifier onlySeller(uint256 listingId) {
        require(listings[listingId].seller == msg.sender, "Not the seller");
        _;
    }

    // Modifier to check if the buyer is not the seller
    modifier notSeller(uint256 listingId) {
        require(listings[listingId].seller != msg.sender, "Seller cannot buy own asset");
        _;
    }

    // Function to list an educational asset for sale
    function listAsset(address assetContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");

        // Ensure the sender owns the asset (ERC721 compliance)
        require(IERC721(assetContract).ownerOf(tokenId) == msg.sender, "You must own the asset");

        listingCount++;
        listings[listingCount] = Listing(msg.sender, price, tokenId, assetContract);

        // Emit the event for the new listing
        emit AssetListed(listingCount, msg.sender, price, tokenId, assetContract);
    }

    // Function to purchase an educational asset
    function purchaseAsset(uint256 listingId) external payable notSeller(listingId) {
        Listing storage listing = listings[listingId];
        
        // Check if the correct amount of Ether is sent
        require(msg.value == listing.price, "Incorrect price");

        // Transfer the asset to the buyer
        IERC721(listing.assetContract).transferFrom(listing.seller, msg.sender, listing.tokenId);

        // Transfer the payment to the seller
        payable(listing.seller).transfer(msg.value);

        // Emit event for the purchase
        emit AssetPurchased(listingId, msg.sender, listing.seller, listing.price, listing.tokenId);

        // Delete the listing
        delete listings[listingId];
    }



    // Function to get details of a listing
    function getListing(uint256 listingId) external view returns (address seller, uint256 price, uint256 tokenId, address assetContract) {
        Listing memory listing = listings[listingId];
        return (listing.seller, listing.price, listing.tokenId, listing.assetContract);
    }
}
