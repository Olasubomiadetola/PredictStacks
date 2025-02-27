# PredictStacks - Stacks Prediction Market Smart Contract

## Overview
This Stacks smart contract implements a decentralized prediction market where users can create events, place bets on different outcomes, resolve events, claim winnings, and receive refunds for canceled events. The contract ensures fairness, security, and transparency while handling bets and payouts.

## Features
- **Event Creation:** Users can create events with multiple options.
- **Bet Placement:** Users can place bets on events before the resolution time.
- **Event Resolution:** The contract owner can resolve events by declaring the winning option.
- **Winnings Claim:** Users can claim their winnings if they bet on the correct outcome.
- **Event Cancellation:** Event creators can cancel events if no bets have been placed.
- **Bet Refunds:** Users can request refunds for canceled events.
- **Odds Calculation:** Users can query the odds of different options.

## Contract Constants
- `contract-owner`: The contract owner (set to `tx-sender` at deployment).
- `fee-percentage`: The percentage of fees taken from the total bets (set to 5%).
- `fee-denominator`: Used to calculate fee amounts (set to 1000).

## Error Codes
- `err-unauthorized (u100)`: Unauthorized action attempted.
- `err-invalid-bet (u101)`: Invalid bet placement.
- `err-event-closed (u102)`: Bet placed on a closed event.
- `err-event-not-resolved (u103)`: Trying to claim winnings for an unresolved event.
- `err-invalid-option (u104)`: Selected an invalid betting option.
- `err-invalid-amount (u105)`: Bet amount is not valid.
- `err-overflow (u106)`: Overflow error in calculations.
- `err-insufficient-balance (u107)`: Not enough balance to place a bet.
- `err-event-not-cancelable (u108)`: Event cannot be canceled.
- `err-no-bets-placed (u109)`: No bets placed for the event.

## Data Structures

### Maps
#### `events`
Stores event details:
```clojure
{ event-id: uint }
{
  description: (string-ascii 256),
  options: (list 10 (string-ascii 64)),
  total-bets: uint,
  is-resolved: bool,
  winning-option: (optional uint),
  resolution-time: uint,
  creator: principal,
  is-canceled: bool
}
```
#### `bets`
Stores user bets:
```clojure
{ event-id: uint, better: principal }
{
  amount: uint,
  option: uint
}
```
#### `event-odds`
Stores odds for each betting option:
```clojure
{ event-id: uint, option: uint }
{ odds: uint }
```

## Public Functions

### `create-event`
Creates a new prediction market event.
#### Parameters:
- `description`: Event description (max 256 chars).
- `options`: List of possible outcomes (max 10 options).
- `resolution-time`: The Unix timestamp after which the event can be resolved.
#### Returns:
- `ok event-id`: Successfully created event ID.
- `err`: Error code if event creation fails.

### `place-bet`
Places a bet on an event.
#### Parameters:
- `event-id`: The event ID.
- `option`: The selected betting option.
- `amount`: The amount of STX being bet.
#### Returns:
- `ok true`: Bet successfully placed.
- `err`: Error code if bet placement fails.

### `resolve-event`
Resolves an event by setting the winning option (only callable by the contract owner).
#### Parameters:
- `event-id`: The event ID.
- `winning-option`: The index of the winning option.
#### Returns:
- `ok true`: Event successfully resolved.
- `err`: Error code if resolution fails.

### `claim-winnings`
Claims winnings for a resolved event.
#### Parameters:
- `event-id`: The event ID.
#### Returns:
- `ok amount`: Amount of winnings transferred.
- `err`: Error code if claim fails.

### `cancel-event`
Cancels an event if no bets have been placed (only callable by the event creator).
#### Parameters:
- `event-id`: The event ID.
#### Returns:
- `ok true`: Event successfully canceled.
- `err`: Error code if cancellation fails.

### `refund-bet`
Refunds a bet if the event is canceled.
#### Parameters:
- `event-id`: The event ID.
#### Returns:
- `ok true`: Refund successfully processed.
- `err`: Error code if refund fails.

## Read-Only Functions

### `get-event`
Retrieves event details.
#### Parameters:
- `event-id`: The event ID.
#### Returns:
- Event details or `none` if the event does not exist.

### `get-bet`
Retrieves bet details for a user.
#### Parameters:
- `event-id`: The event ID.
- `better`: The user's principal address.
#### Returns:
- Bet details or `none` if no bet found.

### `calculate-odds`
Calculates the odds for an event option.
#### Parameters:
- `event-id`: The event ID.
- `option`: The betting option.
#### Returns:
- Odds of the option (percentage).

## Private Functions

### `get-total-bets-for-option`
Calculates the total bets placed on a given option.

### `add-safe`
Performs safe addition to prevent overflow errors.

### `is-active-event`
Checks whether an event is still active.

## Deployment
To deploy this contract, use Clarity tools such as `clarinet` or `stacks-cli`.

1. **Deploy contract**
   ```sh
   clarinet deploy contracts/stx-prediction-market.clar
   ```

2. **Interact with contract**
   Use the `clarinet console` or Stacks Explorer to call public functions.

## Security Considerations
- Only the contract owner can resolve events.
- Users cannot place bets on closed or resolved events.
- Overflow errors are prevented using `add-safe`.
- Withdrawals are only allowed for winning bets.

## License
This contract is open-source and available under the MIT License.

