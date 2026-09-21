# TrustWork Mobile - Web3 Escrow Application

TrustWork is a decentralized milestone escrow application built with Flutter, BLoC State Management, Clean Architecture, and Ethereum Sepolia Smart Contracts.

## Architecture

- **Domain Layer (`lib/domain/`)**: Pure business logic, Entities, UseCases, and Repository Contracts.
- **Data Layer (`lib/data/`)**: Data Sources (Web3Dart, Reown AppKit, Supabase, Pinata IPFS), Models, and Repository Implementations.
- **Presentation Layer (`lib/presentation/`)**: BLoC State Management (`flutter_bloc`) and responsive UI screens.
- **Core Layer (`lib/core/`)**: Dependency injection via `get_it`, constants, errors, and custom theme/animation widgets.

## Key Features

- **Decentralized Escrow 2.0**: Lock funds on-chain using Mock USDC with dynamic percentage milestones.
- **Automated Milestone Release**: Client-driven approval releasing milestone portions directly to the worker's wallet.
- **Dispute Resolution Protocol**: Built-in halt/trigger dispute with designated neutral arbiter resolution.
- **IPFS Evidence Layer**: Upload deliverable proofs to Pinata IPFS off-chain storage.
- **Fluid & Responsive UI**: Smooth spring animations, shimmer loaders, and micro-interactions.

## Getting Started

1. Copy `.env.example` to `.env` and fill in your Supabase, Pinata, and WalletConnect credentials:
   ```bash
   cp .env.example .env
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
