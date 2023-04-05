# Diamond-1-Tracker-Hardhat Implementation

This is derived from the reference  implementation for [EIP-2535 Diamonds](https://github.com/ethereum/EIPs/issues/2535).

Which can be found at [diamond-1-hardhat](https://github.com/mudgen/diamond-1-hardhat/blob/main/README.md)


## Installation

1. Clone this repo:
```console
git clone git@github.com:polysensus/diamond-1-tracker-hardhat.git
```

2. Install NPM packages:
```console
cd diamond-1-tracker-hardhat
npm install
```

## Deployment

Deploy the *target* diamond

```console
node scripts/deploy.js
```

Note the address, then deploy the tracker pointing it at the target address

```console
node scripts/deployTracker.js TARGET-ADDRESS
```


## Author (of the original)

This example implementation was written by Nick Mudge.

Contact:

- https://twitter.com/mudgen
- nick@perfectabstractions.com
- https://github.com/mudgen


## Author (of this fork)

This example was derived from the upstream by Robin Bryce

- https://twitter.com/fupduk
- https://github.com/polysensus
- robin@polysensus.com
- 
## License

MIT license. See the license file.
Anyone can use or modify this software for their purposes.