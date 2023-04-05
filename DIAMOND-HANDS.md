# Centralized upgrades, user opt outs and customizations.

## Context

If we represent the authority of individuals on chain using programable wallets for the "next billion web3 users" how are we going to cope when we need to patch all those wallets for a security vulnerability ?

If we want user wallets to enable rich application specific behavior how are we going to accomplish that composeability on chain ?


The approach described here, and illustrated by the contracts in this repository, is aimed at facilitating mass management of ERC 4337 smart wallets which interact with one or more applications. Those applications may be agnostic to the wallet facilities. Applications may want to provide specialized wallet behavior. Wallet users may want to opt out of specific wallet behavior or customize it.

The primary use case in mind here is online gaming. But the applicability is general.

### Problem 1: user apathy vs security

When a smart wallet implementation needs to be upgraded for a vulnerability, requiring the smart wallet owners to perform the upgrade will lead to most smart wallets never being upgraded.

### Problem 2: operational cost to perform upgrades

Even if a smart wallet vendor was technically able to upgrade millions (or possibly billions) of smart wallet accounts on behalf of their owners, doing so would be prohibitively expensive.

### Problem 3: conflicts of interest between wallet owners and application owners

An extra level of indirection can solve problems 1 & 2 if the extra per call cost is acceptable. But there is no single good answer to reconcile the interests of people who use applications with the makers and publishers of those applications. For smart wallets to solve this problem we need to **at least** permit user opt outs, and probably also user customizations, of shared wallet functionality.

These problems are all very familiar to most software vendors. In games, problem 3 is typically addressed by gamers installing un-official clients and tooling - from the application perspective this is _cheating_

## Approach

We can solve 1 & 2 with an extra level of indirection between the wallet implementation and the user state - simple proxy. This comes at additional per call cost, but especially in the context of ERC 4337 and the indirection already implied by User Operations, this seems like a fair trade. To solve 3, the tracker needs to also be a composable & upgradable implementation - a diamond.

This leads to the two distinct approaches illustrated by this repository:

1. **Tracker** - for when only problems 1&2 matter.
2. **DiamondTracker** - for when 1, 2 & 3 all matter.

The DiamondTracker is a **Double Diamond**, and the first diamond can be thought of as the users **Diamond Hands** holding their smart wallet.
 
### Use Case 1: user accounts for games

Game developers (or a publisher) provide a governed wallet implementation for users of the game or games. Users are typically happy to accept that governance. Some  users MAY want to customise their wallet. Some users MAY want to opt out of some wallet functionality.

Note that the Game Wallet and the Game are two completely independent contract systems. Using the Diamond standard to make the wallet does not itself require that the Game be implemented as a diamond.

The Smart Wallet is essentially a presence and an authority system for some arbitrary application. If the application wants bespoke wallet functionality it is free to define that. But it need not do so.

## Tracker

We use the [diamond][ERC-2535] standard to make a composable and extensible wallet.

We use the [beacon proxy][ZEP-BEACON] model to indirect access to the wallet implementation. This is a _double_ proxy: the tracker follows the wallet implementation.

If we followed the zepplin nomenclature we would re-name the reference Diamond to be DiamondBeacon. This seems un-necessarily confusing to people who have absorbed the Diamond standard. So we formalise from the other end of the relationship - the contract that *follows* the beacon is the **Tracker**

### Smart Wallet interacts with Application (eg a Game)

![fig-1](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/polysensus/diamond-1-tracker-hardhat/main/fig-1.puml)


The user sees the address of the **Tracker** as their Smart Wallet address. Every user has their own address. Each user tracker follows a *vendors* Diamond Wallet implementation. **Governance** between the user and wallet vendor is defined by the specific implementation facets.

### Tracker as a simple proxy

![fig-2](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/polysensus/diamond-1-tracker-hardhat/main/fig-2.puml)

At this point, the Tracker is a simple proxy. Creating a double proxy via Diamond Wallet. The wallet vendor can interact with the Diamond Wallet to perform upgrades, and all Trackers following that wallet implementation will 'track' that implementation automatically.

Notice that while the Application may also be a Diamond, there is no requirement for it to be so. Its implementation is completely outside the scope of the wallet **unless** the wallet vendor is specifically choosing to design the wallet around that application.

## Diamond Tracker

If the wallet wants to provide for user opt outs and extensions in preference to the governed (central) implementation it would be natural to implement the Tracker itself as a Diamond.

![fig-3](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/polysensus/diamond-1-tracker-hardhat/main/fig-3.puml)

* Wallet facets invoked via the Tracker Diamond operate in **User Storage**
* User Facets can _only_ operate in **User Storage**
* Wallet Facets invoked by the vendor directly on the **Diamond Wallet** operate in **Vendor Storage**

### louper diamond tracker rules
This requires a more involved fallback and louper method implementations on the Tracker Diamond.

1. IDiamondCut MUST NOT call  (the owner would be wrong anyway) ??
2. IDiamondLoupe.facets MUST aggregate the facets from the tracked target with the local selectors.
3. IDiamondLoupe.facetFunctionSelectors MUST support local facets and proxied - if the facet isn't local, proxy the call.
4. IDiamondLoupe.facetAddresses MUST aggregate the addresses from the tracked and the remote
5. IDiamondLoupe.facetAddress MUST support local and proxied function selectors



## What does the user see ?

* A wallet address through which they interact with one or more application addresses
* Their personal 'wallet' state
* There 'owned' application state, authorized to their wallet address
* Upgrades to wallet features are automatic
* If the Tracker Diamond is in play
  * some kind of opt in/out mechanism
  * personalisable wallet implementation
* The likely variance in wallet governance implies that users will still want many smart wallets.


## Governance

This indirection necessarily places trust in the wallet vendor. It is for the vendor to define the governance in such that it is acceptable to users of the applications

### Application specific smart wallets

Each application defines an application specific wallet and on boards users with a deployment of a tracker wallet for each application user. The application is the vendor and manages upgrades of the user smart wallet.

The user must decide if they trust the governance rules of the diamond wallet put in place by the application developer.

### Platform specific smart wallets

A common platform implements smart wallet behavior on behalf of many dapps. Each user is on-boarded to the platform and configures one or more dapps supported by that platform. The platform is the vendor and manages upgrades of user smart wallets on behalf of both users and dapp developers.

The user must decide if they trust the governance rules of the diamond wallet put in place by the platform developer.

### Distributed Governance

There is no central vendor for the smart wallet implementation

If the smart wallet vendor is a DAO, can we do away with the Double Diamond all together and instead give the wallet user a place in the governance ? It still seems like an irreconcilable bottle neck - like getting all members of the EU to agree to something. 

The collective will is, by definition, imperfectly aligned with the individuals of that collective.

## TODO's

### How lean can we make the simple proxy ?

## References

* [ERC-2535]: https://eips.ethereum.org/EIPS/eip-2535/
    [Diamonds][ERC-2535]
* [ERC-4337]: https://eips.ethereum.org/EIPS/eip-4337/
    [ERC 4337 Account Abstraction][ERC-4337]
* [ZEP-BEACON]: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/BeaconProxy.sol
    [OpenZeppelin Beacon Proxy][ZEP-BEACON]