import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Prelude "mo:base/Prelude";

actor class NFT (name: Text, owner: Principal, content: [Nat8]) = this{
    private var nftOwner = owner;
    private let itemName = name;
    private let imageByter = content;

    public query func getName() : async Text {
        return itemName;
    };

    public query func getOwner() : async Principal {
        return nftOwner;
    };
    
    public query func getAsset() : async [Nat8] {
        return imageByter;
    };

    public query func getCanisterId() : async Principal {
        return Principal.fromActor(this);
    };

    public shared(msg) func transferOwnership(newOwner : Principal ) : async Text {
        if (msg.caller == nftOwner){
            nftOwner := newOwner;
            return "Success";
        }else{
            return "Error: Func not initiated by the owner";
        }
    };
}
