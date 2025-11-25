;; QuizDAO - Community-sourced Quiz Repository with Decentralized Rewards
;; Create and participate in quizzes with blockchain-based rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u101))
(define-constant err-already-attempted (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-score (err u105))
(define-constant err-quiz-inactive (err u106))
(define-constant err-invalid-difficulty (err u107))
(define-constant err-already-rewarded (err u108))
(define-constant err-minimum-score-not-met (err u109))
(define-constant err-max-attempts-reached (err u110))

;; Data Variables
(define-data-var quiz-nonce uint u0)
(define-data-var attempt-nonce uint u0)
(define-data-var reward-pool uint u0)
(define-data-var total-participants uint u0)
(define-data-var platform-fee-percentage uint u5)
(define-data-var minimum-passing-score uint u70)

;; Data Maps
(define-map quizzes
    uint
    {
        creator: principal,
        title: (string-ascii 100),
        category: (string-ascii 50),
        question-count: uint,
        difficulty: (string-ascii 20),
        reward-amount: uint,
        total-attempts: uint,
        created-at: uint,
        active: bool
    }
)

(define-map quiz-attempts
    uint
    {
        quiz-id: uint,
        participant: principal,
        score: uint,
        max-score: uint,
        timestamp: uint,
        rewarded: bool
    }
)

(define-map user-attempts
    { user: principal, quiz-id: uint }
    (list 10 uint)
)

(define-map creator-stats
    principal
    { quizzes-created: uint, total-rewards-given: uint }
)

(define-map participant-stats
    principal
    { 
        quizzes-attempted: uint, 
        quizzes-passed: uint, 
        total-score: uint,
        total-rewards-earned: uint
    }
)

(define-map quiz-leaderboard
    { quiz-id: uint, rank: uint }
    { participant: principal, score: uint, percentage: uint }
)

(define-map category-stats
    (string-ascii 50)
    { quiz-count: uint, total-attempts: uint }
)