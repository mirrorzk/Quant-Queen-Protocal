# QuantQueen Protocol

![image](https://github.com/mirrorzk/Quant-Queen-Protocol/blob/master/picture/QQB%20UI_1.png)

QuantQueen Protocol is a crypto native token backed by NAV (Net Asset Value)  that represents shares in a quantitative asset portfolio. It combines a protocolized NAV mint/burn cycle, on-chain transparency and verifiability, and free secondary trading on DEXs/CEXs into a single asset. It is designed for users and developers who want to obtain returns with risk exposure while still retaining liquidity and composability.

This repo opens sources and maintains QQB’s core protocol contracts, NAV Oracle interface specifications, risk disclosure standards, and integration tooling, helping ecosystem partners quickly implement issuance, trading, minting, burn, verification, data indexing, and secondary financial applications.

### Enter to [Quant Queen Protocol](https://quantqueen.to/) | [Buy QQB](https://pancakeswap.finance/swap?outputCurrency=0xDBE2c424cEc25999028b0ef4adEaAaF80B56BAbd&chain=bsc&inputCurrency=0x55d398326f99059fF775485246999027B3197955)  |  [Factsheet](https://github.com/mirrorzk/Quant-Queen-Protocol/blob/master/data/Factsheet.pdf)  |  [Strategy Data](https://github.com/mirrorzk/Quant-Queen-Protocol/blob/master/data/nav.csv)




### Contributors: <img src="https://github.com/mirrorzk/Quant-Queen-Protocol/blob/master/picture/matrixport.png" alt="logo" width="20" /> frank.liu@matrixport | <img src="https://github.com/mirrorzk/Quant-Queen-Protocol/blob/master/picture/binance.png" alt="logo" width="20" /> alfred.liu@binance | <img src="https://github.com/mirrorzk/Quant-Queen-Protocol/blob/master/picture/zerobase.jpeg" alt="logo" width="20" /> mirror.tang@zerobase


## 1. Design & Usability

![image](https://github.com/mirrorzk/Quant-Queen-Protocal/blob/master/picture/Product%20Model.png)

### User Experience

- **Minting**  
  Users mint QQB based on the monthly NAV price.

- **Burn**  
  Users submit burn requests and have their QQB redeemed based on the monthly settlement cycle.

- **Trading**  
  Once minted, QQB enters free circulation and can be traded on-chain or on CEXs, combining the properties of an asset backed by NAV with those of a liquid trading asset.


### Developer Experience

- **Contract interfaces**  
  Core behaviors such as `mint`, `burn`, `fee routing`, and `NAV updates` are clearly defined with transparent state machines and boundary conditions.


- **Modular decoupling**  
  The protocol layer, NAVOracle layer, and custodial strategy adapter layer are independent of each other, enabling component swap-outs and feature extensions.

- **Docs and examples**  
  Includes interaction guides, burn fee examples, NAV data structures, and event indexing notes to lower integration friction.

### Expansion Potential

- **Visual usability**  
  A reference dashboard is provided (NAV curve, drawdown ranges, risk metric, burn outcome simulator).

- **Tiered UX**  
  A simplified mode can target retail users, while institutional users can access more granular disclosures and APIs (delayed disclosure, interval-based views, proof summaries).


## 2. Scalability
![image](https://github.com/mirrorzk/Quant-Queen-Protocal/blob/master/picture/Risk%20Model.png)
### Strengths

- **Scale-friendly**  
  Supply expands and contracts dynamically with minting and burning, while pricing is anchored to NAV, making the structure suitable for AUM growth and long-term operation.

- **Run-resistant structure**  
  TVL and supply shrink in sync while burning, structurally reducing systemic risk similar to a classic bank-run collapse.

- **Multi-strategy capacity**  
   Within a unified risk budget and disclosure standard, more strategy modules can be introduced to diversify and stabilize return sources.

### Expansion Potential

- **Higher-frequency NAV publication**  
  Evolve from monthly to weekly/daily NAV disclosure as scale grows, better matching market expectations for transparency and risk management.


- **Factory-style strategy onboarding**  
  Build standardized modules for strategy admission, limit management, risk budget allocation, and automatic de-risking, so onboarding new strategies moves from manual workflows to a standardized framework.

## 3. Innovation

### Strengths

- **New asset paradigm**  
  Combines token backed by NAV with the tradability and composability of tokens, improving efficiency across both primary and secondary markets.


- **New model of asset management**  
  Extends from low-volatility strategy management into medium- and higher-volatility strategies, bringing a new phase of growth for traditional asset management concepts in crypto markets.


- **Closed-loop mechanics**  
  Burning token plus recycling fee express the economic cycle and NAV growth in a structured way, forming sustainable incentives and capital discipline.


- **Verifiable NAV direction**  
  Moves beyond simply publishing a NAV number toward verifiable NAV methodology and disclosure standards, laying the groundwork for institutional-grade trust.


### Expansion Potential

- **Proof-ready NAV**  
  Introduce zero-knowledge proofs, trusted execution environments, and audit attestations to prove the correctness of risk constraints and NAV methodology without revealing sensitive trading details.


- **Structured products**  
  Use QQB as the underlying NAV asset to build options, lending products, and structured derivatives, forming a broader product matrix.


## 4. Integration & Composability

### Core Integrations

- **DEX/CEX dual presence**  
  QQB can trade freely on-chain while also integrating into CEX trading systems, with the mint/burn mechanism remaining verifiable and disciplined.


- **Modular architecture**  
  Custody, Oracle, exchange connectivity, and strategy modules are all pluggable, making it easier to connect with different partners and infrastructure providers.

- **DeFi composability**  
  QQB can serve as collateral, margin, or a yield-bearing base asset, extending into lending, derivatives, and structured products.


### Expansion Potential

- **Standardized integration kits**  
  Provide SDKs (TypeScript/Python), subgraph/indexer templates, trading-pair initialization scripts, and risk parameter recommendations.


- **Multichain & cross-chain liquidity**  
  Expand to additional chains under a unified NAV methodology and provide cross-chain wrappers and compliant liquidity migration solutions.


## 5. Roadmap

### Phase 1 – Infrastructure & Standards

- Protocol contracts v1:  `mint` / `burn` / `fee routing`
- NAV/Oracle interface spec v1 + reference implementation
- Risk disclosure schema v1 + validation tooling
- CI security baseline:
  - Unit tests
  - Invariant testing
  - Fuzzing

### Phase 2 – Mainnet & Ecosystem Onboarding

- Optimized operations and operations playbook (redemption windows, oracle updates, contingency plans)
- DEX liquidity templates and deployment toolkit
- NAV and risk metric visualization

### Phase 3 – Scale-Up & Innovation

- Higher-frequency NAV publication (weekly/daily/delayed disclosure)
- Multi-strategy risk control engine
- Multichain expansion and enhanced composability
- Proof-ready NAV (ZK, TEE, audit proof summaries)


