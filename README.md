## 🧾 Charity Campaign Smart Contract

This smart contract is written in [Clarity](https://docs.stacks.co/docs/write-smart-contracts/clarity-overview) and implements a **decentralized crowdfunding platform** for charity purposes, with support for refunds when campaigns fail.

---

### 📦 Main Features

| Feature                        | Description                                                                 |
| ------------------------------ | --------------------------------------------------------------------------- |
| ✅ Create Campaign              | Anyone can create a fundraising campaign with a goal and deadline           |
| 💸 Donate                      | Users can donate STX to active campaigns                                    |
| 🔒 Only Admin Can Withdraw     | Only the campaign admin can withdraw funds once the goal is reached         |
| 🔁 Enable Refund (Manual/Auto) | Refund can be enabled if the campaign fails after the deadline              |
| 💰 Claim Refund                | Donors can request a refund if the campaign fails                           |
| 📊 Query Support               | Supports querying campaign details, donation status, and refund eligibility |

---

### 🚀 How to Use

#### 1. Create a Campaign

```clarity
(create-campaign admin name goal end-height)
```

* `admin`: wallet address of the campaign manager (can withdraw funds)
* `name`: name of the campaign (string-utf8, max 100 chars)
* `goal`: fundraising target in STX
* `end-height`: block height at which the campaign ends

#### 2. Donate

```clarity
(donate campaign-id amount)
```

* `campaign-id`: the ID of the target campaign
* `amount`: amount of STX to donate

#### 3. Withdraw Funds

```clarity
(withdraw campaign-id amount)
```

* Can only be called by the campaign's `admin`
* Can only be done after the campaign reaches its goal

#### 4. Enable Refund

```clarity
(enable-refund campaign-id) ; only admin  
(auto-enable-refund campaign-id) ; anyone
```

* Enable refunds after deadline if campaign failed

#### 5. Claim Refund

```clarity
(claim-refund campaign-id)
```

* Donors can reclaim their STX if the campaign failed and refunds are enabled

---

### 📚 Read-Only Functions

```clarity
(get-campaign campaign-id)               ; Get campaign details  
(get-donation campaign-id donor)        ; Get amount donated by a user  
(is-refunded campaign-id donor)         ; Check if refund was claimed  
(can-claim-refund campaign-id donor)    ; Check if user is eligible for refund  
(get-campaign-status campaign-id)       ; Get status: active / expired / successful / failed  
(get-current-block-height)              ; Get current block height  
(is-campaign-expired campaign-id)       ; Check if the campaign has ended  
```

---

### ✅ Campaign Statuses

| Status         | Meaning                               |
| -------------- | ------------------------------------- |
| `"active"`     | Campaign is ongoing and not expired   |
| `"expired"`    | Campaign is expired but not processed |
| `"successful"` | Campaign reached its goal             |
| `"failed"`     | Campaign failed and refund is enabled |
| `"not-found"`  | Campaign ID does not exist            |

---

### ⚠️ Error Codes

| Error Name                | Code   | Description                       |
| ------------------------- | ------ | --------------------------------- |
| `err-not-found`           | `u100` | Campaign not found                |
| `err-inactive`            | `u101` | Campaign is not active            |
| `err-expired`             | `u102` | Campaign has expired              |
| `err-transfer-failed`     | `u103` | STX transfer failed               |
| `err-not-admin`           | `u104` | Caller is not the campaign admin  |
| `err-invalid-amount`      | `u105` | Invalid amount                    |
| `err-invalid-campaign-id` | `u106` | Invalid campaign ID               |
| `err-goal-reached`        | `u107` | Campaign already reached its goal |
| `err-goal-not-reached`    | `u108` | Campaign has not reached the goal |
| `err-campaign-not-ended`  | `u109` | Campaign is not yet ended         |
| `err-already-refunded`    | `u110` | Refund already claimed            |
| `err-no-donation`         | `u111` | No donation found for this user   |

---

### 🔧 Data Structures

#### Campaign

```clarity
{
  owner: principal,
  admin: principal,
  name: (string-utf8 100),
  goal: uint,
  total-donated: uint,
  end-height: uint,
  active: bool,
  goal-reached: bool,
  refund-enabled: bool
}
```

#### Donation & Refund Maps

* `donations`: { campaign-id, donor } → amount
* `refunded`: { campaign-id, donor } → bool

---

### ✅ Testing

Use Clarinet to check and test the contract:

```bash
clarinet check
clarinet test
```
## Contract Details
Deployed contract address: ST2XN33GJGH27EGA201V4EBF4Y4M8G8EYQA6JSSBF.charity_campaign_2
<img width="1919" height="1017" alt="image" src="https://github.com/user-attachments/assets/2ac52549-1e36-47f4-bf2a-d4f8d4acbfc5" />
