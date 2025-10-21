Biodiversity Index – On-chain Tokenized Species Registry

Overview

The Biodiversity Index smart contract is a decentralized registry that enables communities, researchers, and citizen scientists to submit, verify, and track species sightings on the Stacks blockchain. Each sighting becomes an immutable, transparent record contributing to a global on-chain biodiversity index. Verified sightings reward contributors and build reputation for both observers and verifiers, fostering a community-driven ecosystem for environmental data integrity.

🌍 Core Features
🐾 1. Submit Sighting

Allows anyone to record a new species sighting, including:

Species name (common and scientific)

Geographic location (latitude, longitude, description)

Timestamp (block height)

Observer information and optional notes

Updates contributor statistics and global counts.

Automatically registers new species if not seen before.

Function:

(define-public (submit-sighting ...))

✅ 2. Verify Sighting

Enables community members to verify unverified sightings.

Ensures verifiers are not the original observers.

Once verified:

The observer’s reputation increases.

The verifier’s total verifications increase.

The sighting is marked as verified.

Designed to support transparent, crowdsourced data validation.

Function:

(define-public (verify-sighting (sighting-id uint)))

💰 3. Verification Rewards

The contract owner can adjust the micro-STX reward for each successful verification.

This value can later be tied to token incentives or external reward mechanisms.

Function:

(define-public (set-verification-reward (new-reward uint)))

📊 Data Structures
Map	Purpose	Key	Value
sightings	Stores all submitted sightings	uint	Sighting details (species, observer, coords, etc.)
species-registry	Tracks unique species and stats	string-ascii	First sighting ID, total sightings, last seen
contributor-stats	Contributor metrics	principal	Total & verified sightings, reputation score
verifier-stats	Verifier metrics	principal	Total verifications, start block
🔍 Read-only Queries
Function	Description
get-sighting(id)	Fetch full details of a specific sighting
get-species-info(name)	View registry data for a species
get-contributor-stats(principal)	Get a contributor’s stats
get-verifier-stats(principal)	Get a verifier’s stats
get-total-species-count()	Total unique species recorded
get-total-sightings()	Total number of sightings submitted
get-verification-reward()	Current micro-STX reward for verification
is-sighting-verified(id)	Returns true if the sighting is verified
🧠 Governance and Access Control

Contract Owner: The deployer (tx-sender at contract creation).

Only the contract owner can adjust system-level parameters like verification rewards.

All submissions and verifications are open to the public (subject to validation logic).

⚙️ Error Codes
Error	Code	Meaning
err-owner-only	u100	Only owner can perform this action
err-not-found	u101	Sighting not found
err-already-verified	u102	Sighting already verified
err-unauthorized	u103	User not authorized for action
err-invalid-data	u104	Input data invalid or missing
🚀 Future Extensions

🪙 Integration with fungible or NFT tokens to represent verified biodiversity data

📡 Oracle integration for GPS or environmental metadata

🌱 Machine learning validation via external APIs

🧭 Geo-fencing and region-based tracking dashboards

📜 Version

Version: 1.0.0

License: MIT

🧾 Example Flow

Alice submits a sighting for African Grey Parrot → stored as ID #0.

Bob verifies Alice’s sighting → sighting becomes verified, Alice gains reputation, Bob gains verifier points.

Owner adjusts verification reward for future verifiers.

✅ Testing Checklist

 Submitting valid and invalid sightings

 Verifying unverified sightings

 Preventing self-verification

 Updating contributor and verifier stats correctly

 Adjusting verification reward (owner-only)

 Reading species and sighting data