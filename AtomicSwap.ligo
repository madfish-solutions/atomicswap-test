type myNonFungibleToken_Token is record
  mintedBy : address;
  mintedAt : nat;
end;

type supportsInterface_args is record
  interfaceID_ : bytes;
end;

type totalSupply_args is unit;
type balanceOf_args is record
  owner_ : address;
end;

type ownerOf_args is record
  tokenId_ : nat;
end;

type approve_args is record
  to_ : address;
  tokenId_ : nat;
end;

type transfer_args is record
  to_ : address;
  tokenId_ : nat;
end;

type transferFrom_args is record
  from_ : address;
  to_ : address;
  tokenId_ : nat;
end;

type tokensOfOwner_args is record
  owner_ : address;
end;

type mint_args is unit;
type getToken_args is record
  tokenId_ : nat;
end;

type state is record
  name : string;
  symbol : string;
  interfaceID_ERC165 : bytes;
  interfaceID_ERC721 : bytes;
  tokens : map(nat, myNonFungibleToken_Token);
  tokenIndexToOwner : map(nat, address);
  ownershipTokenCount : map(address, nat);
  tokenIndexToApproved : map(nat, address);
end;

const myNonFungibleToken_Token_default : myNonFungibleToken_Token = record [ mintedBy = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);
	mintedAt = 0n ];

type router_enum is
  | SupportsInterface of supportsInterface_args
  | TotalSupply of totalSupply_args
  | BalanceOf of balanceOf_args
  | OwnerOf of ownerOf_args
  | Approve of approve_args
  | Transfer of transfer_args
  | TransferFrom of transferFrom_args
  | TokensOfOwner of tokensOfOwner_args
  | Mint of mint_args
  | GetToken of getToken_args;

(* EventDefinition Transfer(from : address; res__to : address; tokenId : nat) *)

(* EventDefinition Approval(owner : address; approved : address; tokenId : nat) *)

(* EventDefinition Mint(owner : address; tokenId : nat) *)

function owns_ (const self : state; const claimant_ : address; const tokenId_ : nat) : (bool) is
  block {
    skip
  } with (((case self.tokenIndexToOwner[tokenId_] of | None -> ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address) | Some(x) -> x end) = claimant_));

function approvedFor_ (const self : state; const claimant_ : address; const tokenId_ : nat) : (bool) is
  block {
    skip
  } with (((case self.tokenIndexToApproved[tokenId_] of | None -> ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address) | Some(x) -> x end) = claimant_));

function approve_ (const self : state; const to_ : address; const tokenId_ : nat) : (state) is
  block {
    self.tokenIndexToApproved[tokenId_] := to_;
    (* EmitStatement Approval(, , _tokenId) *)
  } with (self);

function transfer_ (const self : state; const from_ : address; const to_ : address; const tokenId_ : nat) : (state) is
  block {
    self.ownershipTokenCount[to_] := (case self.ownershipTokenCount[to_] of | None -> 0n | Some(x) -> x end) + 1;
    self.tokenIndexToOwner[tokenId_] := to_;
    if (from_ =/= ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address)) then block {
      self.ownershipTokenCount[from_] := (case self.ownershipTokenCount[from_] of | None -> 0n | Some(x) -> x end) - 1;
      remove tokenId_ from map self.tokenIndexToApproved;
    } else block {
      skip
    };
    (* EmitStatement Transfer(_from, _to, _tokenId) *)
  } with (self);

function mint_ (const self : state; const owner_ : address) : (state * nat) is
  block {
    const tokenId : nat = 0n;
    const token : myNonFungibleToken_Token = record [ mintedBy = owner_;
    	mintedAt = abs(abs(now - ("1970-01-01T00:00:00Z": timestamp))) ];
    const tmp_0 : map(nat, myNonFungibleToken_Token) = self.tokens;
    tmp_0[size(tmp_0)] := tokwn;
    tokenId := size(tmp_0) - 1n;
    (* EmitStatement Mint(_owner, tokenId) *)
    transfer_(self, 0, owner_, tokenId);
  } with (self, tokenId);

function supportsInterface (const self : state; const interfaceID_ : bytes) : (list(operation)) is
  block {
    skip
  } with ((nil: list(operation)));

function totalSupply (const self : state) : (list(operation)) is
  block {
    skip
  } with ((nil: list(operation)));

function balanceOf (const self : state; const owner_ : address) : (list(operation)) is
  block {
    skip
  } with ((nil: list(operation)));

function ownerOf (const self : state; const tokenId_ : nat) : (list(operation)) is
  block {
    const owner : address = (case self.tokenIndexToOwner[tokenId_] of | None -> ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address) | Some(x) -> x end);
    assert((owner =/= ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address)));
  } with ((nil: list(operation)));

function approve (const self : state; const to_ : address; const tokenId_ : nat) : (list(operation) * state) is
  block {
    assert(owns_(self, sender, tokenId_));
    approve_(self, to_, tokenId_);
  } with ((nil: list(operation)), self);

function transfer (const self : state; const to_ : address; const tokenId_ : nat) : (list(operation) * state) is
  block {
    assert((to_ =/= ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address)));
    assert((to_ =/= self_address));
    assert(owns_(self, sender, tokenId_));
    transfer_(self, sender, to_, tokenId_);
  } with ((nil: list(operation)), self);

function transferFrom (const self : state; const from_ : address; const to_ : address; const tokenId_ : nat) : (list(operation) * state) is
  block {
    assert((to_ =/= ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address)));
    assert((to_ =/= self_address));
    assert(approvedFor_(self, sender, tokenId_));
    assert(owns_(self, from_, tokenId_));
    transfer_(self, from_, to_, tokenId_);
  } with ((nil: list(operation)), self);

function tokensOfOwner (const self : state; const owner_ : address) : (list(operation)) is
  block {
    const res__balance : nat = balanceOf(self, owner_);
    if (res__balance = 0n) then block {
      skip
    } else block {
      const result : map(nat, nat) = map end (* args: res__balance *);
      const maxTokenId : nat = totalSupply(self);
      const idx : nat = 0n;
      const tokenId : nat = 0n;
      tokenId := 1n;
      while (tokenId <= maxTokenId) block {
        if ((case self.tokenIndexToOwner[tokenId] of | None -> ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address) | Some(x) -> x end) = owner_) then block {
          result[idx] := tokenId;
          idx := idx + 1;
        } else block {
          skip
        };
        tokenId := tokenId + 1;
      };
    };
  } with ((nil: list(operation)));

function mint (const self : state) : (list(operation) * state) is
  block {
    skip
  } with ((nil: list(operation)), self);

function getToken (const self : state; const tokenId_ : nat) : (list(operation)) is
  block {
    const token : myNonFungibleToken_Token = (case self.tokens[tokenId_] of | None -> myNonFungibleToken_Token_default | Some(x) -> x end);
    const mintedBy : address = token.mintedBy;
    const mintedAt : nat = token.mintedAt;
  } with ((nil: list(operation)));

function main (const action : router_enum; const self : state) : (list(operation) * state) is
  (case action of
  | SupportsInterface(match_action) -> (supportsInterface(self, match_action.interfaceID_), self)
  | TotalSupply(match_action) -> (totalSupply(self), self)
  | BalanceOf(match_action) -> (balanceOf(self, match_action.owner_), self)
  | OwnerOf(match_action) -> (ownerOf(self, match_action.tokenId_), self)
  | Approve(match_action) -> approve(self, match_action.to_, match_action.tokenId_)
  | Transfer(match_action) -> transfer(self, match_action.to_, match_action.tokenId_)
  | TransferFrom(match_action) -> transferFrom(self, match_action.from_, match_action.to_, match_action.tokenId_)
  | TokensOfOwner(match_action) -> (tokensOfOwner(self, match_action.owner_), self)
  | Mint(match_action) -> mint(self)
  | GetToken(match_action) -> (getToken(self, match_action.tokenId_), self)
  end);
