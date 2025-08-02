# Good Night API

Rails API for tracking users' sleep and viewing weekly sleep rankings among followed users.

---

## Features
> Users can log when they sleep/wake and compare weekly sleep stats with friends.
- Record when users go to bed and wake up (single `clock_in` endpoint)
- Follow and unfollow other users
- View weekly sleep records of following users, sorted by sleep duration
- Designed for scalability: caching, indexing, background jobs, and clean architecture

---

## Tech Stack

- **Ruby**: 3.0.0
- **Rails**: 7.1.0 (API mode)
- **PostgreSQL**: Supports complex queries and offers excellent scalability
- **Redis**: Used for caching leaderboards and personal sleep record
- **RSpec**: Used for testing

---

## Setup

```bash
# Clone repository
git clone https://github.com/Rae-Lee/sleep_tracker_rails.git
cd sleep_tracker_rails
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Run server
rails s
API will be available at http://localhost:3000.

# Testing
bundle exec rspec
```

---

# API Endpoints

## 1. Sleep Records

### Clock In (Sleep / Wake)

**Endpoint**

```http
POST /sleep_records/clock_in
```
- If no incomplete record → create new sleep_at
- If has incomplete record → update wake_at

### List User Records

**Endpoint**

```http
GET /sleep_records?user_id=1
```
- Returns all user's sleep records ordered by created_at.

## 2. Follow

### Follow a User

**Endpoint**

```http
POST /follows
```
### Unfollow a User

**Endpoint**

```http
DELETE /follows/:id
```

## 3. Weekly Rankings of Followings

### Get Weekly Rankings

**Endpoint**

```http
GET /followings/sleep_records?user_id=1
```
- Returns all followings' sleep records from previous week (Mon–Sun), sorted by total sleep duration.
