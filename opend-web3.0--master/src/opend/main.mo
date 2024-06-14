import NFTActorClass "../NFT/nft";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import List "mo:base/List";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";

actor OpenD {

    private type Listing = {
        itemOwner : Principal;
        itemPrice : Nat;
    };

    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1,Principal.equal,Principal.hash);
    var mapOfNFTs = HashMap.HashMap<Principal,NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    var mapOfListings = HashMap.HashMap<Principal,Listing>(1, Principal.equal, Principal.hash);
 
    public shared(msg) func mint(imgData: [Nat8], name: Text): async Principal{
        let owner = msg.caller;

        Debug.print(debug_show(Cycles.balance()));
        Cycles.add(100_500_000_000);
        let newNFT = await NFTActorClass.NFT(name,owner,imgData);
        Debug.print(debug_show(Cycles.balance()));
        
        let newNFTPrincipal = await newNFT.getCanisterId();
        mapOfNFTs.put(newNFTPrincipal,newNFT);
        addToOwnerShipMap(owner,newNFTPrincipal);

        return newNFTPrincipal;
    };

    private func addToOwnerShipMap(owner: Principal, nftId: Principal){
        var ownedNFTs: List.List<Principal> = switch (mapOfOwners.get(owner)){
            case null List.nil<Principal>();
            case (?result) result;
        };

        ownedNFTs := List.push(nftId,ownedNFTs);
        mapOfOwners.put(owner,ownedNFTs);
    };

    public query func getOwnedNFTs(user:Principal) : async [Principal]{
        var ownedNFTs: List.List<Principal> = switch (mapOfOwners.get(user)){
            case null List.nil<Principal>();
            case (?result) result;
        };
        return List.toArray(ownedNFTs);
    };

    public shared(msg) func listItem(id: Principal, price: Nat): async Text{
        var item : NFTActorClass.NFT = switch (mapOfNFTs.get(id)){
            case null return "NFT doesn't exist";
            case (?result) result;
        };

        let owner = await item.getOwner();
        if (Principal.equal(owner, msg.caller)){
            let newListing : Listing = {
                itemOwner = owner;
                itemPrice = price;
            };

            mapOfListings.put(id,newListing);
            return "Success";
        }else {
            return "You don't own the NFT.";
        }
    };

    public query func getOpenDId() : async Principal{
        return Principal.fromActor(OpenD);
    };

    public query func isListed(id: Principal): async Bool {
        if(mapOfListings.get(id) == null){
            return false;
        }else{
            return true;
        }
    };

    public query func getListedNFTs(): async [Principal]{
        return Iter.toArray(mapOfListings.keys());
    };

    public query func getOriginalOwner(id : Principal ): async Principal {
        var listing : Listing = switch(mapOfListings.get(id)) {
            case(?value) { value };
            case(null) { return Principal.fromText("") };
        }; 

        return listing.itemOwner;
    };

    public query func getPrice(id : Principal ): async Nat {
        var listing : Listing = switch(mapOfListings.get(id)) {
            case(null) { return 0 };
            case(?value) { value };
        }; 

        return listing.itemPrice;
    };

    public shared(msg) func completePurchase(id: Principal, ownerId: Principal, newOnwerId: Principal): async Text{
        var purchasedNFT : NFTActorClass.NFT = switch(mapOfNFTs.get(id)){
            case null return "NFT doesn't exist";
            case (?result) result;
        };

        let transferResult = await purchasedNFT.transferOwnership(newOnwerId);

        if(transferResult == "Success"){
            mapOfListings.delete(id);
            var ownedNFTs : List.List<Principal> = switch (mapOfOwners.get(ownerId)){
                case null List.nil<Principal>();
                case (?result ) result;
            };

            ownedNFTs := List.filter(ownedNFTs, func (listItemId : Principal): Bool{
                return listItemId != id;
            });
            mapOfOwners.put(ownerId,ownedNFTs);
            addToOwnerShipMap(newOnwerId, id);
            return "Success";
        }else{
            return transferResult;
        }
    };
};
