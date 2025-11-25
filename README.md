# QuizDAO - Decentralized Quiz Repository

A community-sourced quiz platform with blockchain-based rewards, enabling educators to create quizzes and students to earn rewards for participation.

## Features

- Decentralized quiz creation and management
- Blockchain-tracked quiz attempts and scores
- Community reward pool system
- Creator statistics and leaderboards
- Quiz difficulty and category classification

## Smart Contract Functions

### Public Functions

- `create-quiz` - Create a new quiz with reward settings
- `submit-attempt` - Submit a quiz attempt with score
- `contribute-to-pool` - Add funds to the reward pool
- `toggle-quiz-status` - Activate or deactivate a quiz (creator only)

### Read-Only Functions

- `get-quiz` - Retrieve quiz details
- `get-attempt` - Retrieve attempt details
- `get-user-attempts` - Get all attempts by a user for a quiz
- `get-creator-stats` - Get statistics for a quiz creator
- `get-reward-pool` - Check current reward pool balance
- `get-quiz-count` - Get total number of quizzes
- `calculate-percentage` - Calculate score percentage

## Usage

Educators create quizzes on-chain with defined rewards. Students attempt quizzes and their scores are permanently recorded. High-performing participants can earn rewards from the community pool.

## Technology Stack

- Stacks Blockchain
- Clarity Smart Contracts