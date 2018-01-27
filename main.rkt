#lang braidbot/insta
(require racket/string)

;; Set the bot-id, bot-token, and braid-url in environment variables.
;; If doing this, you'd run the bot like
;; BOT_ID='...' BOT_TOKEN='...' BRAID_URL='...' racket -t main.rkt
(define bot-id "5a6cc117-b777-478f-9d57-61b9bfd2b95e")
(define bot-token "hz4MI_DcwlHwr8Bks-qE9nzpxPwvEor9nWmGCA7O")
(define braid-url "http://localhost:5557")

;; set the port the bot will listen on
(listen-port 8989)

;; set a function to run on startup
(on-init (λ () (println "Bot starting")))

(define todo-re #rx"^/todobot (.*)$")
(define (parse-message text)
  (second (regexp-match todo-re text)))

(define db (make-hash))

(define (store-todo msg)
  (let* ([todo (parse-message (hash-ref msg '#:content))]
        [user (hash-ref msg '#:user-id)]
        [todos (hash-ref! db user '())])
    (hash-set! db user (cons todo todos))))

(define (list-todos user)
  (hash-ref! db user '()))

;; required function you must implement
;; `msg` is the decoded message that the bot has recieved
;; note that, if it's a mention, the content will begin with `/botname`
(define (act-on-message msg)
  (store-todo msg)
  (let ([todos (list-todos (hash-ref msg '#:user-id))])
    (reply-to msg (string-join todos "\n")
              #:bot-id bot-id
              #:bot-token bot-token
              #:braid-url braid-url)))

