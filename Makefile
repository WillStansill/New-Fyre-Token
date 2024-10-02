-include .env

.PHONY: build test deploy deploy-fyre deploy-treasury mint transfer

# Build the contracts
build:
	forge build

# Run the test suite
test:
	forge test

# Deploy the FyreToken contract
deploy-fyre:
	@forge script script/DeployFyreToken.s.sol --rpc-url $(RPC_URL) --broadcast --private-key $(PRIVATE_KEY) --legacy

# Deploy the VerusTreasury contract
deploy-treasury:
	@forge script script/DeployVerusTreasury.s.sol --rpc-url $(RPC_URL) --broadcast --private-key $(PRIVATE_KEY) --legacy

# Deploy both FyreToken and VerusTreasury
deploy:
	make deploy-fyre
	# Update the FYRE_TOKEN_ADDRESS in the .env after this command
	make deploy-treasury

# Mint new tokens to a specified address
mint:
	@cast send $(FYRE_TOKEN_ADDRESS) "mint(address,uint256)" $(OWNER_ADDRESS) $(AMOUNT) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --json

# Transfer tokens from OWNER_ADDRESS to another address
transfer:
	@cast send $(FYRE_TOKEN_ADDRESS) "transfer(address,uint256)" $(TO_ADDRESS) $(AMOUNT) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --json
