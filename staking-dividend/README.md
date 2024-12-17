# STX Dividend Distribution Smart Contract

## About
This smart contract implements a dividend distribution system for STX tokens on the Stacks blockchain. It allows for automatic distribution of dividends to token holders based on their staked balance, with built-in mechanisms for claiming dividends and managing unclaimed amounts.

## Features
- Automated dividend distribution based on staked token amounts
- Proportional dividend calculation system
- Claim mechanism for token holders
- Unclaimed dividend management
- Administrative controls for dividend pool management
- Real-time balance tracking

## Contract Variables

### Constants
- `CONTRACT-ADMIN`: The administrator address (contract deployer)
- `MINIMUM-PAYOUT-BLOCK-INTERVAL`: Minimum block interval (10000) before unclaimed dividends can be withdrawn

### State Variables
- `cumulative-dividend-pool`: Total amount of dividends added to the contract
- `dividend-rate-per-token`: Calculated rate of dividends per staked token
- `previous-dividend-block`: Block height of the last dividend distribution
- `total-staked-tokens`: Total number of tokens staked in the contract
- `total-claimed-dividends`: Total amount of dividends claimed by users

## Core Functions

### Administrative Functions
1. `add-dividends (dividend-amount uint)`
   - Adds new dividends to the distribution pool
   - Only callable by contract administrator
   - Updates dividend rate per token

2. `withdraw-unclaimed-dividends ()`
   - Allows withdrawal of unclaimed dividends after the minimum payout interval
   - Only callable by contract administrator
   - Requires unclaimed dividends to exist

### User Functions
1. `claim-dividends ()`
   - Allows users to claim their available dividends
   - Automatically updates user's staked balance
   - Transfers claimed amount to user

2. `update-staked-balance ()`
   - Updates the user's staked token balance
   - Updates total staked tokens in the contract
   - Returns current staked balance

### Read-Only Functions
1. `get-dividend-rate-per-token ()`
   - Returns current dividend rate per token

2. `get-claimable-dividends (account principal)`
   - Calculates claimable dividends for a given account

3. `get-contract-balance ()`
   - Returns current contract balance

## Error Codes
- `ERR-ADMIN-ONLY (u100)`: Operation restricted to administrator
- `ERR-NO-PAYOUTS (u101)`: No dividends available for claiming
- `ERR-TRANSFER-FAILED (u102)`: STX transfer operation failed
- `ERR-INVALID-SUM (u103)`: Invalid dividend amount
- `ERR-UPDATE-HOLDINGS-FAILED (u104)`: Failed to update user holdings
- `ERR-PAYOUT-PERIOD-NOT-REACHED (u105)`: Minimum payout interval not reached
- `ERR-NO-UNCLAIMED-PAYOUTS (u106)`: No unclaimed dividends available

## Usage Examples

### Adding Dividends
```clarity
(contract-call? .dividend-distribution add-dividends u1000000)
```

### Claiming Dividends
```clarity
(contract-call? .dividend-distribution claim-dividends)
```

### Checking Claimable Amount
```clarity
(contract-call? .dividend-distribution get-claimable-dividends tx-sender)
```

## Security Considerations
1. Administrative functions are protected with principal checks
2. Dividend calculations use safe arithmetic operations
3. State updates are atomic and consistent
4. Minimum payout interval prevents frequent withdrawals of unclaimed dividends

## Deployment Prerequisites
1. STX tokens for contract deployment
2. Administrative wallet for contract management
3. Understanding of dividend distribution mechanics

## Integration Guidelines
1. Ensure proper contract initialization
2. Maintain accurate staked token balances
3. Regular monitoring of dividend pool and claims
4. Implementation of proper error handling in client applications

## Contract Limitations
1. Fixed minimum payout interval
2. No partial dividend claims
3. Administrative privileges cannot be transferred
4. Dividend rate calculations round down to nearest integer

## Best Practices
1. Regularly update staked balances
2. Monitor unclaimed dividends
3. Verify dividend calculations before claims
4. Keep track of dividend distribution events