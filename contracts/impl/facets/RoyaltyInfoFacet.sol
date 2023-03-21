// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream
import {Modifiers} from "../../storage/LibAppStorage.sol";

contract RoyaltyInfoFacet is Modifiers {

    /**
     * @notice Used to retrieve the recipient of royalties.
     * @return Address of the recipient of royalties
     */
    function getRoyaltyRecipient() public view returns (address) {
        return s._royaltyRecipient;
    }

    /**
     * @notice Used to retrieve the specified royalty percentage.
     * @return The royalty percentage expressed in the basis points
     */
    function getRoyaltyPercentage() public view returns (uint256) {
        return s._royaltyPercentageBps;
    }

    /**
     * @notice Used to retrieve the information about who shall receive royalties of a sale of the specified token and
     *  how much they will be.
     * @param tokenId ID of the token for which the royalty info is being retrieved
     * @param salePrice Price of the token sale
     * @return receiver The beneficiary receiving royalties of the sale
     * @return royaltyAmount The value of the royalties recieved by the `receiver` from the sale
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = s._royaltyRecipient;
        royaltyAmount = (salePrice * s._royaltyPercentageBps) / 10000;
    }
}