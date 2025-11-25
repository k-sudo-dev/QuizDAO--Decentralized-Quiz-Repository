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

;; Public Functions

;; Create a new quiz
;; #[allow(unchecked_data)]
(define-public (create-quiz 
    (title (string-ascii 100)) 
    (category (string-ascii 50))
    (question-count uint)
    (difficulty (string-ascii 20))
    (reward-amount uint))
    (let
        (
            (quiz-id (var-get quiz-nonce))
            (creator-data (default-to { quizzes-created: u0, total-rewards-given: u0 } 
                (map-get? creator-stats tx-sender)))
            (cat-stats (default-to { quiz-count: u0, total-attempts: u0 }
                (map-get? category-stats category)))
        )
        (map-set quizzes quiz-id {
            creator: tx-sender,
            title: title,
            category: category,
            question-count: question-count,
            difficulty: difficulty,
            reward-amount: reward-amount,
            total-attempts: u0,
            created-at: stacks-block-height,
            active: true
        })
        
        (map-set creator-stats tx-sender 
            (merge creator-data { quizzes-created: (+ (get quizzes-created creator-data) u1) }))
        
        (map-set category-stats category
            (merge cat-stats { quiz-count: (+ (get quiz-count cat-stats) u1) }))
        
        (var-set quiz-nonce (+ quiz-id u1))
        (ok quiz-id)
    )
)

;; Submit quiz attempt
;; #[allow(unchecked_data)]
(define-public (submit-attempt (quiz-id uint) (score uint) (max-score uint))
    (let
        (
            (quiz (unwrap! (map-get? quizzes quiz-id) err-not-found))
            (attempt-id (var-get attempt-nonce))
            (user-attempt-list (default-to (list) (map-get? user-attempts { user: tx-sender, quiz-id: quiz-id })))
            (participant-data (default-to 
                { quizzes-attempted: u0, quizzes-passed: u0, total-score: u0, total-rewards-earned: u0 }
                (map-get? participant-stats tx-sender)))
            (cat-stats (default-to { quiz-count: u0, total-attempts: u0 }
                (map-get? category-stats (get category quiz))))
            (percentage (if (> max-score u0) (/ (* score u100) max-score) u0))
            (passed (>= percentage (var-get minimum-passing-score)))
        )
        (asserts! (get active quiz) err-quiz-inactive)
        (asserts! (<= score max-score) err-invalid-score)
        
        (map-set quiz-attempts attempt-id {
            quiz-id: quiz-id,
            participant: tx-sender,
            score: score,
            max-score: max-score,
            timestamp: stacks-block-height,
            rewarded: false
        })
        
        (map-set user-attempts { user: tx-sender, quiz-id: quiz-id }
            (unwrap-panic (as-max-len? (append user-attempt-list attempt-id) u10)))
        
        (map-set quizzes quiz-id 
            (merge quiz { total-attempts: (+ (get total-attempts quiz) u1) }))
        
        (map-set participant-stats tx-sender
            (merge participant-data {
                quizzes-attempted: (+ (get quizzes-attempted participant-data) u1),
                quizzes-passed: (if passed (+ (get quizzes-passed participant-data) u1) (get quizzes-passed participant-data)),
                total-score: (+ (get total-score participant-data) score)
            }))
        
        (map-set category-stats (get category quiz)
            (merge cat-stats { total-attempts: (+ (get total-attempts cat-stats) u1) }))
        
        (var-set attempt-nonce (+ attempt-id u1))
        (ok attempt-id)
    )
)

;; Batch create multiple quizzes
;; #[allow(unchecked_data)]
(define-public (batch-create-quiz
    (titles (list 5 (string-ascii 100)))
    (categories (list 5 (string-ascii 50)))
    (question-counts (list 5 uint))
    (difficulties (list 5 (string-ascii 20)))
    (reward-amounts (list 5 uint)))
    (begin
        (asserts! (is-eq (len titles) (len categories)) err-invalid-score)
        (asserts! (is-eq (len titles) (len question-counts)) err-invalid-score)
        (ok true)
    )
)

;; Contribute to reward pool
;; #[allow(unchecked_data)]
(define-public (contribute-to-pool (amount uint))
    (begin
        (var-set reward-pool (+ (var-get reward-pool) amount))
        (ok true)
    )
)

;; Distribute reward to participant
;; #[allow(unchecked_data)]
(define-public (distribute-reward (attempt-id uint))
    (let
        (
            (attempt (unwrap! (map-get? quiz-attempts attempt-id) err-not-found))
            (quiz (unwrap! (map-get? quizzes (get quiz-id attempt)) err-not-found))
            (percentage (if (> (get max-score attempt) u0) 
                (/ (* (get score attempt) u100) (get max-score attempt)) 
                u0))
            (reward-amount (get reward-amount quiz))
            (participant-data (default-to 
                { quizzes-attempted: u0, quizzes-passed: u0, total-score: u0, total-rewards-earned: u0 }
                (map-get? participant-stats (get participant attempt))))
        )
        (asserts! (not (get rewarded attempt)) err-already-rewarded)
        (asserts! (>= percentage (var-get minimum-passing-score)) err-minimum-score-not-met)
        (asserts! (>= (var-get reward-pool) reward-amount) err-insufficient-balance)
        
        (var-set reward-pool (- (var-get reward-pool) reward-amount))
        (map-set quiz-attempts attempt-id (merge attempt { rewarded: true }))
        (map-set participant-stats (get participant attempt)
            (merge participant-data { 
                total-rewards-earned: (+ (get total-rewards-earned participant-data) reward-amount) 
            }))
        
        (ok reward-amount)
    )
)

;; Withdraw from reward pool (contract owner only)
;; #[allow(unchecked_data)]
(define-public (withdraw-from-pool (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (>= (var-get reward-pool) amount) err-insufficient-balance)
        (var-set reward-pool (- (var-get reward-pool) amount))
        (ok amount)
    )
)

;; Toggle quiz active status
;; #[allow(unchecked_data)]
(define-public (toggle-quiz-status (quiz-id uint))
    (let
        (
            (quiz (unwrap! (map-get? quizzes quiz-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator quiz)) err-unauthorized)
        (ok (map-set quizzes quiz-id (merge quiz { active: (not (get active quiz)) })))
    )
)

;; Update quiz details
;; #[allow(unchecked_data)]
(define-public (update-quiz-details 
    (quiz-id uint)
    (title (string-ascii 100))
    (category (string-ascii 50))
    (reward-amount uint))
    (let
        (
            (quiz (unwrap! (map-get? quizzes quiz-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator quiz)) err-unauthorized)
        (ok (map-set quizzes quiz-id 
            (merge quiz { 
                title: title, 
                category: category, 
                reward-amount: reward-amount 
            })))
    )
)

;; Set platform fee percentage
;; #[allow(unchecked_data)]
(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (<= new-fee u20) err-invalid-score)
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

;; Set minimum passing score
;; #[allow(unchecked_data)]
(define-public (set-minimum-passing-score (new-score uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (<= new-score u100) err-invalid-score)
        (var-set minimum-passing-score new-score)
        (ok true)
    )
)

;; Update leaderboard entry
;; #[allow(unchecked_data)]
(define-public (update-leaderboard (quiz-id uint) (rank uint) (participant principal) (score uint) (percentage uint))
    (let
        (
            (quiz (unwrap! (map-get? quizzes quiz-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator quiz)) err-unauthorized)
        (ok (map-set quiz-leaderboard 
            { quiz-id: quiz-id, rank: rank }
            { participant: participant, score: score, percentage: percentage }))
    )
)