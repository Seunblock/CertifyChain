# Course Certificate NFT Smart Contract

The **Course Certificate NFT Smart Contract** implements an educational certificate system based on the **SIP-009** NFT standard. It allows educational institutions or authorized issuers to issue, manage, and verify NFTs as certificates for students who complete specific courses. The system includes features such as course registration, certificate issuance, revocation, and verification.

## Features

- **NFT-based Certificates**: Certificates are issued as non-fungible tokens (NFTs) to students upon successful course completion.
- **Course Registration**: Courses can be registered by the contract owner, specifying course details such as name, description, and duration.
- **Issuer Management**: Only authorized issuers can issue certificates. The contract owner manages the list of authorized issuers.
- **Certificate Management**: Issued certificates can be revoked and verified for validity. Certificates are tied to student information, course details, grades, and expiration dates.
- **Contract Pause/Unpause**: The contract owner can pause and unpause the contract for administrative purposes.

## Contract Structure

### Constants

- **CONTRACT_OWNER**: The address that owns and manages the contract.
- **ERR_NOT_AUTHORIZED**: Error code for unauthorized access.
- **ERR_ALREADY_EXISTS**: Error code for duplicate entries (e.g., course or issuer).
- **ERR_INVALID_CERTIFICATE**: Error code for invalid certificate data.
- **ERR_CERTIFICATE_REVOKED**: Error code for revoked certificates.
- **ERR_INVALID_USER**: Error code for invalid user actions.
- **ERR_NOT_FOUND**: Error code when data is not found.

### Data Structures

- **certificate-counter**: Tracks the current certificate ID for minting new certificates.
- **contract-paused**: A flag to indicate if the contract is paused or active.

#### Maps

- **certificate-details**: Stores details for each issued certificate, including student ID, course details, grades, expiration date, and validity status.
- **authorized-issuers**: Stores information about authorized issuers, including their name, active status, and total certificates issued.
- **course-registry**: Stores details about registered courses, including course name, description, duration, and creation date.

### Functions

#### Administrative Functions

- **pause-contract**: Pauses the contract (only accessible by the contract owner).
- **unpause-contract**: Unpauses the contract (only accessible by the contract owner).
- **register-course**: Registers a new course with a unique course ID, name, description, and duration (only accessible by the contract owner).
- **add-authorized-issuer**: Adds a new authorized issuer with a unique principal address (only accessible by the contract owner).
- **deactivate-issuer**: Deactivates an authorized issuer (only accessible by the contract owner).

#### Certificate Functions

- **issue-certificate**: Issues a certificate to a student upon course completion. The certificate is minted as an NFT and stored on the blockchain.
- **revoke-certificate**: Revokes an issued certificate, rendering it invalid.
- **get-certificate**: Retrieves details of a certificate by its ID.
- **verify-certificate**: Verifies the validity of a certificate, ensuring it has not been revoked and is not expired.

#### Read-Only Functions

- **get-issuer-details**: Retrieves details about an authorized issuer.
- **get-course-details**: Retrieves details about a registered course.
- **get-last-token-id**: Returns the last issued certificate ID (the current token ID counter).
- **get-token-uri**: Retrieves the metadata URI for a certificate.
- **get-owner**: Returns the owner (holder) of the NFT certificate.

#### SIP-009 NFT Interface

- **transfer**: This function is not implemented as certificates are non-transferable.
  
## Usage

### 1. Admin Functions

The contract owner can manage courses and issuers:

- **Pause Contract**: Pauses all contract activity.
- **Unpause Contract**: Resumes contract activity.
- **Register Course**: Adds new courses to the system.
- **Add Authorized Issuer**: Grants permission to an issuer to issue certificates.
- **Deactivate Issuer**: Removes an issuer's permission to issue certificates.

### 2. Issuing Certificates

Authorized issuers can issue certificates by calling the `issue-certificate` function with the following parameters:

- **student-id**: A unique identifier for the student.
- **student-address**: The student's address (principal).
- **course-id**: The ID of the completed course.
- **grade**: The grade received by the student (a number between 0 and 100).
- **metadata-uri**: A URI that points to additional metadata for the certificate.
- **expiration-date**: An optional expiration date for the certificate (if applicable).

The certificate will be minted as an NFT, and the details will be stored on the blockchain.

### 3. Verifying Certificates

To verify a certificate, anyone can call the `verify-certificate` function with the certificate ID. This will return whether the certificate is valid or revoked and whether it has expired.

### 4. Revoking Certificates

Authorized issuers or the contract owner can revoke certificates using the `revoke-certificate` function. Once revoked, a certificate becomes invalid.

## Security Considerations

- **Access Control**: Only the contract owner can register courses and add authorized issuers. Only authorized issuers can issue certificates.
- **Certificate Revocation**: Issued certificates can be revoked by the issuer or contract owner.
- **Paused State**: The contract owner can pause the contract to prevent further actions if needed.

## Future Improvements

- **Upgradeability**: Implementing an upgradeable contract pattern to allow contract modifications in the future.
- **Token Transfers**: Allow certificates to be transferred between addresses (currently not supported).
- **Expiration Date Handling**: Implement more flexible expiration logic for certificates.