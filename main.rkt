#lang braidbot/insta
(require racket/string)

;; Set the bot-id, bot-token, and braid-url in environment variables.
;; If doing this, you'd run the bot like
;; BOT_ID='...' BOT_TOKEN='...' BRAID_URL='...' racket -t main.rkt
(define bot-id "5a63a020-2e4e-4abf-97aa-45997265fafa")
(define bot-token "snoR2Tp3PPHrQaLl62WnnEw7xGE29XO5gMgZxMAS")
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
    (reply-to msg (string-join todos)
              #:bot-id bot-id
              #:bot-token bot-token
              #:braid-url braid-url)))

