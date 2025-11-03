# Makefile for running foundry tests
# Usage:
# - Prerequisites:
#   - Run `yarn install` to install all dependencies via Yarn.
#   - Run `foundryup` to ensure Foundry is up-to-date.
#   - Run `forge install` to install all foundry dependencies.
# - Commands:
#   - `make install`         : Install all dependencies defined in .gitmodules using Foundry's forge install.
#   - `make run_fork`        : Run an anvil fork on the BASE_LOCAL_FORK_PORT using the base RPC URL.
#   - `make run_arb_fork`    : Run an anvil fork on the ARB_LOCAL_FORK_PORT using the ARB RPC URL.
#   - `make test`            : Run all tests using forge with any optional arguments specified in --args.
#                              For example: `make test args="--match-test Deposit"`

include ./.env
include ./.env.tokens
include ./.env.clccip
include ./.env.clf
include ./.env.deployments.mainnet
include ./.env.deployments.testnet
include ./.env.wallets
include .env.foundry

ENV_FILES := ./.env ./.env.tokens ./.env.clccip ./.env.clf ./.env.deployments.mainnet ./.env.deployments.testnet ./.env.wallets .env.foundry
export $(shell cat $(ENV_FILES) | sed 's/=.*//' | sort | uniq)
args =

all: test

install:
	grep -E '^\s*url' ./.gitmodules | awk '{print $$3}' | xargs -I {} sh -c 'forge install {}'

test:
	forge test $(args)

coverage:
	forge coverage --report lcov
	genhtml --ignore-errors inconsistent --ignore-errors corrupt -o ./coverage_report ./lcov.info
	open ./coverage_report/index.html
	rm -rf lcov.info

#coverage:
#	forge coverage --report lcov --skip script
#	lcov --include lcov.info 'src/**' -o lcov.src.info
#	genhtml -o ./coverage_report --ignore-errors inconsistent,corrupt lcov.src.info
#	open ./coverage_report/index.html
#	rm -f lcov.info lcov.src.info

.PHONY: all test
