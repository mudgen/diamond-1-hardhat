# Centralized upgrades, user opt outs and customizations.

Intended for mass management of ERC 4337 smart wallets which interact with one or more applications. Those applications may be agnostic to the wallet facilities. Applications may want to provide specialized wallet behaviour. Wallet users may want to opt out of specific wallet behaviour or customize it.

## Context

If we represent the authority of individuals on chain using programable wallets for the "next billion web3 users" how are we going to cope when we need to patch all those wallets for a security vulnerability ?

If we want user wallets to enable rich application specific behaviour how are we going to accomplish that composeability on chain ?

### Problem 1: user apathy vs security

When a smart wallet implementation needs to be upgraded for a vulnerability, requiring the smart wallet owners to perform the upgrade will lead to most smart wallets never being upgraded.

### Problem 2: operational cost to perform upgrades

Even if a smart wallet vendor was technically able to upgrade millions (or possibly billions) of smart wallet accounts on behalf of their owners, doing so would be prohibitively expensive.
 
### Use Case 1: user accounts for games

Game developers (or a publisher) provide a governed wallet implementation for users of the game or games. Users are typically happy to accept that governance. Some  users MAY want to customise their wallet. Some users MAY want to opt out of some wallet functionality.

Note that the Game Wallet and the Game are two completely independent contract systems. Using the Diamond standard to make the wallet does not itself require that the Game be implemented as a diamond.

The Smart Wallet is essentially a presence and an authority system for some arbitrary application. If the application wants bespoke wallet functionality it is free to define that. But it need not do so.

## Tracker

We use the [diamond][ERC-2535] standard to make a composable and extensible wallet.

We use the [beacon proxy][ZEP-BEACON] model to indirect access to the wallet implementation. This is a _double_ proxy: the tracker follows the wallet implementation.

If we followed the zepplin nomenclature we would re-name the reference Diamond to be DiamondBeacon. This seems un-necessarily confusing to people who have absorbed the Diamond standard. So we formalise from the other end of the relationship - the contract that *follows* the beacon is the **Tracker**

## Smart Wallet interacts with Application (eg a Game)

```plantuml
@startuml
skinparam componentStyle rectangle
User -> [Smart Wallet]
cloud UserOperations{
    [4337 Bundler]
}
[Smart Wallet] .> [4337 Bundler]
[4337 Bundler] .> [Application]
@enduml
```


The user sees the address of the **Tracker** as their Smart Wallet address. Every user has their own address. Each user tracker follows a *vendors* Diamond Wallet implementation. **Governance** between the user and wallet vendor is defined by the specific implementation facets.

```plantuml
@startuml
skinparam componentStyle rectangle
package "Smart Wallet" {
    database "User Storage" {
    }

    database "Vendor Storage" {
    }

    [Tracker] -> [Diamond Wallet]
    [Diamond Wallet] ..> [Wallet Facets]
    [Tracker] --> [User Storage]
    [Diamond Wallet] --> [Vendor Storage]

}
cloud UserOperations{
}

User --> [Tracker]
Vendor --> [Diamond Wallet]

[Diamond Wallet] -> [UserOperations]

@enduml
```

At this point, the Tracker is a simple proxy. Creating a double proxy via Diamond Wallet. The wallet vendor can interact with the Diamond Wallet to perform upgrades, and all Trackers following that wallet implementation will 'track' that implementation automatically.

I think of the Tacker, with an ERC 4337 implementation, as my **diamond hands**

Notice that while the Application may also be a Diamond, there is no requirement for it to be so. Its implementation is completely outside the scope of the wallet **unless** the wallet vendor is specifically choosing to design the wallet around that application.

If the wallet wants to provide for user opt outs and extensions in preference to the governed (central) implementation it would be natural to implement the Tracker itself as a Diamond.

```plantuml
@startuml
skinparam componentStyle rectangle
package "Smart Wallet" {
    database "User Storage" {
    }

    database "Vendor Storage" {
    }

    [Tracker Diamond] -> [Diamond Wallet]
    [Tracker Diamond] ..> [User Facets]
    [Diamond Wallet] ..> [Wallet Facets]
    [Tracker Diamond] --> [User Storage]
    [Diamond Wallet] --> [Vendor Storage]

}
cloud UserOperations{
}

User --> [Tracker Diamond]
Vendor --> [Diamond Wallet]

[Diamond Wallet] -> [UserOperations]

@enduml
```

This requires a more involved fallback and louper method implementations on the Tracker Diamond.

## What does the user see ?

* A wallet address through which they interact with one or more application addresses
* Their personal 'wallet' state
* There 'owned' application state, authorized to their wallet address
* Upgrades to wallet features are automatic
* If the Tracker Diamond is in play
  * some kind of opt in/out mechanism
  * personalisable wallet implementation
* The likely variance in wallet governance implies that users will have many smart wallets.


## Governance

This indirection necessarily places trust in the wallet vendor. It is for the vendor to define the governance in such that it is acceptable to users of the applications

### Application specific smart wallets

Each application defines an application specific wallet and on boards users with a deployment of a tracker wallet for each application user. The application is the vendor and manages upgrades of the user smart wallet.

The user must decide if they trust the governance rules of the diamond wallet put in place by the application developer.

### Platform specific smart wallets

A common platform implements smart wallet behaviour on behalf of many dapps. Each user is onboarded to the platform and configures one or more dapps supported by that platform. The platform is the vendor and manages upgrades of user smart wallets on behalf of both users and dapp developers.

The user must decide if they trust the governance rules of the diamond wallet put in place by the platform developer.

### Distributed Governance

There is no central vendor for the smart wallet implementation

## TODO's

### How lean can we make the simple proxy ?

Q1: try to use a proxy that only has fallback. does it 'fallback' to IDiamondLoupe and IDiamondCut as implemented in the target diamond ?

A1: this doesn't work because the fallback causes the diamond method to execute in the storage of the tracker which DOES NOT HAVE the diamond methods etc

## References

* [ERC-2535]: https://eips.ethereum.org/EIPS/eip-2535/
    [Diamonds][ERC-2535]
* [ERC-4337]: https://eips.ethereum.org/EIPS/eip-4337/
    [ERC 4337 Account Abstraction][ERC-4337]
* [ZEP-BEACON]: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/BeaconProxy.sol
    [OpenZeppelin Beacon Proxy][ZEP-BEACON]