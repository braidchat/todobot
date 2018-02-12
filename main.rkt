#lang braidbot/insta
(require
  racket/string
  db
  braidbot/uuid
  braidbot/util)

;; Set the bot-id, bot-token, and braid-url in environment variables.
;; If doing this, you'd run the bot like
;; BOT_ID='...' BOT_TOKEN='...' BRAID_URL='...' racket -t main.rkt
(define bot-id "5a7b5657-6f0e-4345-b153-1a1b6a419ab9")
(define bot-token "daO_NO11mgNWb-yKS_CJI08ZDu9DSQmBg0VMKCbG")
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

(define (store-todo msg todo)
  (let ([user (hash-ref msg '#:user-id)])
    (query-exec con "insert into todos (user_id, content) values ($1 , $2)"
                (uuid->string user) todo)))

(define (list-todos user)
  (query-rows con "select rowid, content from todos where user_id=$1"
              (uuid->string user)))

(define (complete-todo todo-id)
  (query-exec con "delete from todos where rowid = $1" todo-id))


(define (format-row row)
  (format "~a. ~a" (vector-ref row 0) (vector-ref row 1)))

(define (reply msg content)
   (reply-to msg content
             #:bot-id bot-id
             #:bot-token bot-token
             #:braid-url braid-url))

(define msg-handlers (list
                      (cons #px"^/todobot\\s+list"
                            (λ (msg matches)
                              (let* ([user-id (hash-ref msg '#:user-id)]
                                     [todos (map format-row (list-todos user-id))])
                                (reply msg (string-join todos "\n")))))
                      (cons #px"^/todobot\\s+add (.*)$"
                            (λ (msg matches)
                              (let ([todos (string-split (first matches) ", ")])
                               (for ([todo todos])
                                  (store-todo msg todo))
                               (reply msg (~a "added " (length todos))))))
                      (cons #px"^/todobot\\s+done\\s+(\\d+)$"
                            (lambda (msg matches)
                              (let ([todo-id
                                     (~> matches first string->number)])
                                (complete-todo todo-id)
                                (reply msg (~a "completed " todo-id)))))))

(define (act-on-message msg)
  (let ([content (hash-ref msg '#:content)])
    (for/first ([re-fn msg-handlers]
                #:when (regexp-match (car re-fn) content))
      ((cdr re-fn) msg (cdr (regexp-match (car re-fn) content))))))

;; required function you must implement
;; `msg` is the decoded message that the bot has recieved
;; note that, if it's a mention, the content will begin with `/botname`

