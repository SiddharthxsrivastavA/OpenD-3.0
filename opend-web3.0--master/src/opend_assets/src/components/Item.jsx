import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import { Actor, HttpAgent} from "@dfinity/agent";
import { Principal } from "@dfinity/principal"
import {idlFactory} from "../../../declarations/NFT";
import {idlFactory as tokenIdlFactory} from "../../../declarations/token";
// import { NFT, canisterId } from "../../../declarations/NFT/index";
import Button from "./Button";
import {opend} from "../../../declarations/opend";
import CURRENT_USER_ID from "../index";
import PriceLabel from "./PriceLabel";

function Item(props) {

  const [Name, setName] = useState();
  const [Owner,setOwner] = useState();
  const[Asset,setAsset] = useState();
  const [button, setButton] = useState();
  const [input, setInput] = useState();
  const [loader, setLoader] = useState(true);
  const [blur, setBlur] = useState();
  const [sellStatus, setSellStatus] = useState();
  const [priceLabel  , setPriceLabel] = useState();
  const [shouldDisplay, setDisplay] = useState(true);

  const id = props.id;
  const localHost = "http://localhost:8080/"
  const agent = new HttpAgent({host:localHost})
  // TODO : delete this line of code when deploying this project online.
  agent.fetchRootKey();
  let NFTActor;

  async function loadNft() {
    NFTActor = await Actor.createActor(idlFactory,
      {agent,
      canisterId: id,}
    )

    const name = await NFTActor.getName();
    setName(name);
    const owner = await NFTActor.getOwner();
    setOwner(owner.toText());
    const asset = await NFTActor.getAsset();
    const assetContent = new Uint8Array(asset);
    const assetUrl = URL.createObjectURL(new Blob([assetContent.buffer],{type: "image/png"}))
    setAsset(assetUrl);


    if(props.role == "collection"){

      const isNftListed = await opend.isListed(props.id);
      if (isNftListed){
        setOwner("OpenD");
        setBlur({filter : "blur(4px)"});
        setSellStatus(" Listed");
      }else{
        setButton(<Button handleClick={handleSell} text="Sell" />)
      }
    }else if (props.role == "Discover"){
      const originalOwner = await opend.getOriginalOwner(props.id);

      if(originalOwner.toText() != CURRENT_USER_ID.toText()){
        setButton(<Button handleClick={handleBuy} text="Buy" />)
      }

      const price = await opend.getPrice(props.id);
      setPriceLabel(<PriceLabel price= {price.toString()}/>);
    }
  };

  let price;
  function handleSell() {
    console.log("sell clicked");
    setInput(<input
      placeholder="Price in DANG"
      type="number"
      className="price-input"
      value={price}
      onChange={(e) => (price = e.target.value)}
    />);
    setButton(<Button handleClick={sellItem} text="Confirm" />)
  }

  async function handleBuy(){
    console.log("Buy clicked");
    setLoader(false);
    const tokenActor = Actor.createActor(tokenIdlFactory,
      {
        agent,
        canisterId: Principal.fromText("tfuft-aqaaa-aaaaa-aaaoq-cai"),
      })

    const sellerId = await opend.getOriginalOwner(props.id);
    const price = await opend.getPrice(props.id);
    
    const result = await tokenActor.transfer(sellerId,price);
    console.log(result);

    if(result == "Success" ){
      let purchaseResult = await opend.completePurchase(props.id,sellerId,CURRENT_USER_ID);
      setLoader(true);
      setDisplay(false);
      console.log("Purchase " + purchaseResult);
    }
  }

  async function sellItem() {
    setBlur({filter : "blur(4px)"});
    setLoader(false);
    console.log("Selling amount = " + price);
    const listingResult = await opend.listItem(props.id,Number(price));
    console.log("listing " + listingResult);

    if (listingResult == "Success"){
      const openDId = await opend.getOpenDId();
      const transferResult = await NFTActor.transferOwnership(openDId);
      console.log(transferResult);
      if (transferResult == "Success"){
        setLoader(true);
        setButton();
        setInput();
        setOwner("OpenD");
        setSellStatus(" Listed");
      }
    }
  }

  useEffect(() => {
    loadNft();
  },[])

  return (
    <div style = {{display : shouldDisplay ? "inline" : "none"}}className="disGrid-item">
      <div className="disPaper-root disCard-root makeStyles-root-17 disPaper-elevation1 disPaper-rounded">
        <img
          className="disCardMedia-root makeStyles-image-19 disCardMedia-media disCardMedia-img"
          src={Asset}
          style={blur}
        />
        <div hidden={loader} className="lds-ellipsis">
          <div></div>
          <div></div>
          <div></div>
          <div></div>
        </div>
        <div className="disCardContent-root">
          {priceLabel}
          <h2 className="disTypography-root makeStyles-bodyText-24 disTypography-h5 disTypography-gutterBottom">
            {Name}<span className="purple-text">{sellStatus}</span>
          </h2>
          <p className="disTypography-root makeStyles-bodyText-24 disTypography-body2 disTypography-colorTextSecondary">
            Owner: {Owner}
          </p>
          {input}
          {button}
        </div>
      </div>
    </div>
  );
}

export default Item;
