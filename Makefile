TOP_DIR=.

VERSION=$(strip $(shell cat version))
ELIXIR_VERSION=$(strip $(shell cat .elixir_version))
OTP_VERSION=$(strip $(shell cat .otp_version))

build:
	@echo "Building the software..."
	@make format

format:
	@mix compile; mix format;

init: install dep
	@echo "Initializing the repo..."

travis-init:
	@echo "Initialize software required for travis (normally ubuntu software)"

install:
	@echo "Install software required for this repo..."
	@mix local.hex --force
	@mix local.rebar --force

dep:
	@echo "Install dependencies required for this repo..."
	@mix deps.get

pre-build: dep
	@echo "Running scripts before the build..."

post-build:
	@echo "Running scripts after the build is done..."

all: pre-build build post-build

test:
	@echo "Running test suites..."
	@MIX_ENV=test make build
	@MIX_ENV=test mix test

test-cov:
	@echo "Running test suites with codecov..."
	@MIX_ENV=test mix do compile --warnings-as-errors, coveralls.json --umbrella

dialyzer:
	@echo "Running dialyzer..."
	@mix dialyzer

doc:
	@echo "Building the documentation..."

precommit: pre-build build post-build test-cov

travis: precommit

travis-deploy:
	@echo "Deploy the software by travis"
	@make release

clean:
	@echo "Cleaning the build..."

watch:
	@make build
	@echo "Watching templates and slides changes..."
	@fswatch -o lib/ | xargs -n1 -I{} make build

run:
	@echo "Running the software..."
	@iex -S mix

submodule:
	@git submodule update --init --recursive

rebuild-deps:
	@rm -rf mix.lock;
	@make dep

cloc:
	@cloc lib test

include .makefiles/*.mk

.PHONY: build init travis-init install dep pre-build post-build all test dialyzer doc precommit travis clean watch run bump-version create-pr submodule cloc
