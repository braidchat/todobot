#lang braidbot/insta
(require
  racket/string
  db
  braidbot/uuid)

;; Set the bot-id, bot-token, and braid-url in environment variables.
;; If doing this, you'd run the bot like
;; BOT_ID='...' BOT_TOKEN='...' BRAID_URL='...' racket -t main.rkt
(define bot-id "5a6cc117-b777-478f-9d57-61b9bfd2b95e")
(define bot-token "hz4MI_DcwlHwr8Bks-qE9nzpxPwvEor9nWmGCA7O")
(define braid-url "http://localhost:5557")

;; set the port the bot will listen on
(listen-port 8989)

;; set a function to run on startup

(define con (sqlite3-connect #:database "todo.sqlite"
                             #:mode 'create))


(on-init (λ () (println "Bot starting")
           (query-exec con
            "create table if not exists todos
             (id rowid, user_id text, content text)")))

(define db (make-hash))

(define (store-todo msg todo)
  (let ([user (hash-ref msg '#:user-id)])
    (query-exec con "insert into todos (user_id, content) values ($1 , $2)"
                (uuid->string user) todo)))

(define (list-todos user)
  (query-list con "select content from todos where user_id=$1"
              (uuid->string user)))

(define msg-handlers (list
                      (cons #px"^/todobot\\s+list"
                            (λ (msg matches)
                              (let* ([user-id (hash-ref msg '#:user-id)]
                                     [todos (list-todos user-id)])
                                (reply-to msg (string-join todos "\n")
                                           #:bot-id bot-id
                                           #:bot-token bot-token
                                           #:braid-url braid-url))))
                      (cons #px"^/todobot\\s+add (.*)$"
                            (λ (msg matches)
                              (store-todo msg (first matches))))))

(define (act-on-message msg)
  (let ([content (hash-ref msg '#:content)])
    (for/first ([re-fn msg-handlers]
                #:when (regexp-match (car re-fn) content))
      ((cdr re-fn) msg (cdr (regexp-match (car re-fn) content))))))

;; required function you must implement
;; `msg` is the decoded message that the bot has recieved
;; note that, if it's a mention, the content will begin with `/botname`

