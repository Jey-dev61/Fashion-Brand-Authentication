# Fashion Brand Authentication

A blockchain-based authentication system to combat counterfeiting and verify fashion brand products.

## Features

- **Brand Registration**: Secure registration system for fashion brands
- **Product Authentication**: Unique blockchain-based product verification
- **Anti-Counterfeiting**: Built-in measures to detect and report fake products
- **Consumer Verification**: Easy authenticity checking for consumers
- **Reward System**: Incentives for reporting counterfeit items

## Contract Functions

### Public Functions
- `register-brand`: Register a new fashion brand
- `verify-brand`: Verify brand authenticity (admin only)
- `authenticate-product`: Add authenticated products to blockchain
- `verify-product-authenticity`: Check if a product is authentic
- `report-counterfeit`: Report suspected counterfeit items
- `verify-counterfeit-report`: Verify counterfeit reports (admin only)
- `claim-counterfeit-reward`: Claim rewards for verified reports
- `transfer-product-ownership`: Transfer product ownership

### Read-Only Functions
- `get-brand-info`: Retrieve brand information
- `get-product-info`: Get product authentication details
- `get-product-owner`: Check current product owner
- `get-user-brand`: Get user's registered brand
- `get-user-rewards`: Check user's earned rewards
- `check-product-authenticity`: Verify product authenticity status

## Usage

Fashion brands register and authenticate their products on the blockchain, while consumers can verify authenticity and report counterfeits to earn rewards.