;;; test-suite.scm — exercise core SIOD language features under sanitisers
;;;
;;; Run with:  build/siod test-suite.scm
;;;
;;; Any failure calls (error ...) which exits non-zero.
;;; Uses only SIOD built-ins — no R5RS names that SIOD lacks.

;;; ── helpers ──────────────────────────────────────────────────────────────

(define pass-count 0)
(define fail-count 0)

(define (check-equal label got expected)
  (cond ((equal? got expected)
         (set! pass-count (+ pass-count 1)))
        ('else
         (set! fail-count (+ fail-count 1))
         (writes nil "FAIL " label ": got " got " expected " expected "\n"))))

(define (check-true label val)
  (check-equal label (if val t ()) t))

;;; ── arithmetic ───────────────────────────────────────────────────────────

(check-equal "add"       (+ 1 2)       3)
(check-equal "sub"       (- 10 3)      7)
(check-equal "mul"       (* 4 5)       20)
(check-equal "div"       (/ 10 2)      5)
(check-equal "neg"       (- 0 7)       -7)
(check-equal "float-add" (+ 1.5 2.5)   4.0)
(check-equal "max"       (max 3 7 2)   7)
(check-equal "min"       (min 3 7 2)   2)
(check-equal "abs-pos"   (abs 5)       5)
(check-equal "abs-neg"   (abs -5)      5)
(check-equal "pow"       (pow 2 10)    1024.0)
(check-equal "sqrt"      (sqrt 9)      3.0)
(check-equal "fmod"      (fmod 17 5)   2.0)
(check-equal "exp-log"   (trunc (exp (log 42))) 42.0)

;;; ── comparison ───────────────────────────────────────────────────────────

(check-true  "lt"        (< 1 2))
(check-true  "gt"        (> 2 1))
(check-true  "le"        (<= 2 2))
(check-true  "ge"        (>= 3 2))
(check-true  "eq-num"    (= 42 42))
(check-true  "not-lt"    (not (< 3 3)))

;;; ── boolean ──────────────────────────────────────────────────────────────

(check-true  "and-true"  (and t t t))
(check-true  "and-false" (not (and t () t)))
(check-true  "or-true"   (or () t))
(check-true  "or-false"  (not (or () ())))
(check-true  "not-false" (not ()))
(check-true  "not-true"  (not (not t)))

;;; ── list operations ──────────────────────────────────────────────────────

(check-equal "cons"     (cons 1 2)            '(1 . 2))
(check-equal "list"     (list 1 2 3)          '(1 2 3))
(check-equal "car"      (car '(a b c))        'a)
(check-equal "cdr"      (cdr '(a b c))        '(b c))
(check-equal "cadr"     (cadr '(1 2 3))       2)
(check-equal "null-t"   (null? '())           t)
(check-equal "null-f"   (null? '(1))          ())
(check-equal "pair-t"   (pair? '(1 2))        t)
(check-equal "pair-f"   (pair? 42)            ())
(check-equal "length"   (length '(a b c d))   4)
(check-equal "append"   (append '(1 2) '(3 4)) '(1 2 3 4))
(check-equal "reverse"  (reverse '(1 2 3))    '(3 2 1))
(check-equal "nth"      (nth 1 '(a b c))      'b)
(check-equal "assoc"    (assoc 2 '((1 . a) (2 . b) (3 . c))) '(2 . b))
(check-equal "assq"     (assq 'b '((a 1)(b 2)(c 3))) '(b 2))
(check-equal "memq"     (memq 'b '(a b c))    '(b c))
(check-equal "member"   (member 2 '(1 2 3))   '(2 3))
(check-equal "last"     (car (last '(1 2 3))) 3)

;;; ── mapcar / subset / apply ──────────────────────────────────────────────

(check-equal "mapcar"   (mapcar (lambda (x) (* x x)) '(1 2 3 4))
             '(1 4 9 16))
(check-equal "subset"   (subset (lambda (x) (= (fmod x 2) 1)) '(1 2 3 4 5))
             '(1 3 5))
(check-equal "apply"    (apply + '(1 2 3 4)) 10)
(check-equal "apply-list" (apply list '(a b c)) '(a b c))

;;; ── string operations ────────────────────────────────────────────────────

(check-equal "string-append" (string-append "foo" "bar") "foobar")
(check-equal "string-length" (string-length "hello")      5)
(check-equal "substring"     (substring "hello" 1 3)     "el")
(check-equal "number->string"(number->string 42)          "42")
(check-equal "string->number"(string->number "99")        99)
(check-equal "string-upcase" (string-upcase "hello")     "HELLO")
(check-equal "string-downcase"(string-downcase "WORLD")  "world")
(check-equal "string?"       (string? "x")                t)
(check-equal "string-equal"  (equal? "abc" "abc")         t)
(check-equal "string-lessp"  (if (string-lessp "abc" "abd") t ()) t)
(check-equal "string-search" (string-search "ll" "hello") 2)
(check-equal "string-trim"      (string-trim       "  hi  ") "hi")
(check-equal "string-trim-left" (string-trim-left  "  hi  ") "hi  ")
(check-equal "string-trim-right"(string-trim-right "  hi  ") "  hi")
(check-equal "strbreakup"    (strbreakup "a:b:c" ":")    '("a" "b" "c"))

;;; ── symbol operations ────────────────────────────────────────────────────

(check-equal "symbol?"     (symbol? 'foo)        t)
(check-equal "intern"      (intern "hello")      'hello)
(check-equal "symbolconc"  (symbolconc 'foo 'bar) 'foobar)
(check-equal "typeof-sym"  (typeof 'x)           'tc_symbol)
(check-equal "typeof-num"  (typeof 42)           'tc_flonum)
(check-equal "typeof-str"  (typeof "x")          'tc_string)
(check-equal "typeof-cons" (typeof '(1))         'tc_cons)

;;; ── let / let* / letrec ──────────────────────────────────────────────────

(check-equal "let"    (let ((x 3) (y 4)) (+ x y))         7)
(check-equal "let*"   (let* ((x 3) (y (* x 2))) y)         6)
(check-equal "letrec" (letrec ((my-even? (lambda (n) (if (= n 0) t (my-odd? (- n 1)))))
                               (my-odd?  (lambda (n) (if (= n 0) () (my-even? (- n 1))))))
                        (list (my-even? 10) (my-odd? 7)))
             '(t t))

;;; ── closures and higher-order functions ──────────────────────────────────

(define (make-adder n) (lambda (x) (+ x n)))
(define add5 (make-adder 5))
(check-equal "closure"   (add5 10)  15)
(check-equal "closure-2" (add5 -3)  2)

(define (compose f g) (lambda (x) (f (g x))))
(check-equal "compose"   ((compose add5 (make-adder 10)) 1) 16)

;;; ── recursion ────────────────────────────────────────────────────────────

(define (fib n)
  (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))

(check-equal "fib-0"  (fib 0)  0)
(check-equal "fib-1"  (fib 1)  1)
(check-equal "fib-10" (fib 10) 55)
(check-equal "fib-20" (fib 20) 6765)

(define (fact n)
  (if (= n 0) 1 (* n (fact (- n 1)))))

(check-equal "fact-0"  (fact 0)  1)
(check-equal "fact-5"  (fact 5)  120)
(check-equal "fact-10" (fact 10) 3628800)

;;; ── tail-recursive accumulator ───────────────────────────────────────────

(define (sum-to n)
  (define (loop acc i)
    (if (> i n) acc (loop (+ acc i) (+ i 1))))
  (loop 0 1))

(check-equal "sum-1-to-100"  (sum-to 100)  5050)
(check-equal "sum-1-to-1000" (sum-to 1000) 500500)

;;; ── while loop ───────────────────────────────────────────────────────────

(let ((i 0) (s 0))
  (while (< i 10)
    (set! s (+ s i))
    (set! i (+ i 1)))
  (check-equal "while-sum" s 45))

;;; ── cond ─────────────────────────────────────────────────────────────────

(define (classify n)
  (cond ((< n 0) 'negative)
        ((= n 0) 'zero)
        ((< n 10) 'small)
        ('else 'large)))

(check-equal "cond-neg"   (classify -3) 'negative)
(check-equal "cond-zero"  (classify 0)  'zero)
(check-equal "cond-small" (classify 7)  'small)
(check-equal "cond-large" (classify 99) 'large)

;;; ── begin / set! ─────────────────────────────────────────────────────────

(define counter 0)
(begin (set! counter (+ counter 1))
       (set! counter (+ counter 1))
       (set! counter (+ counter 1)))
(check-equal "begin-set!" counter 3)

;;; ── prog1 ────────────────────────────────────────────────────────────────

(check-equal "prog1" (prog1 1 2 3) 1)

;;; ── vectors (SIOD arrays) ────────────────────────────────────────────────

(let ((v (cons-array 5)))
  (aset v 2 99)
  (check-equal "vector-set/ref" (aref v 2) 99)
  (check-equal "vector-length"  (length v)  5))

;;; ── hash tables ──────────────────────────────────────────────────────────

(let ((h (cons-array 17)))
  (hset h 'key1 "val1")
  (hset h 'key2 42)
  (check-equal "hash-string" (href h 'key1) "val1")
  (check-equal "hash-number" (href h 'key2) 42)
  (check-equal "hash-miss"   (href h 'missing) ()))

;;; ── variable-arity functions ─────────────────────────────────────────────

(define (sum . args)
  (letrec ((loop (lambda (l acc)
                   (if (null? l) acc (loop (cdr l) (+ acc (car l)))))))
    (loop args 0)))

(check-equal "varargs-0" (sum)           0)
(check-equal "varargs-3" (sum 1 2 3)     6)
(check-equal "varargs-5" (sum 1 2 3 4 5) 15)

;;; ── catch/throw ──────────────────────────────────────────────────────────

(check-equal "catch-no-throw"
             (*catch 'myerr 42)
             42)

(check-equal "catch-throw"
             (*catch 'myerr (*throw 'myerr 'escaped))
             'escaped)

;;; ── qsort / string-lessp ─────────────────────────────────────────────────

(check-equal "qsort-strings"
             (qsort '("banana" "apple" "cherry") string-lessp)
             '("apple" "banana" "cherry"))

;;; ── bit operations ───────────────────────────────────────────────────────

(check-equal "bit-and"  (bit-and 12 10)   8)
(check-equal "bit-or"   (bit-or  12 10)  14)
(check-equal "bit-xor"  (bit-xor 12 10)   6)
(check-equal "bit-not"  (bit-and (bit-not 0) 255) 255)
(check-equal "ash-left" (ash 1 4)         16)
(check-equal "ash-right"(ash 16 -4)        1)

;;; ── copy-list ────────────────────────────────────────────────────────────

(let ((orig '(1 2 3)))
  (let ((copy (copy-list orig)))
    (set-car! copy 99)
    (check-equal "copy-list-isolation" (car orig) 1)
    (check-equal "copy-list-copy"      (car copy) 99)))

;;; ── nconc / nreverse ─────────────────────────────────────────────────────

(check-equal "nreverse" (nreverse (list 1 2 3)) '(3 2 1))
(check-equal "nconc"    (nconc (list 1 2) (list 3 4)) '(1 2 3 4))

;;; ── deep recursion (stack stress) ───────────────────────────────────────

(define (count-down n)
  (if (= n 0) 'done (count-down (- n 1))))

(check-equal "deep-recursion" (count-down 5000) 'done)

;;; ── GC stress: allocate many cons cells ─────────────────────────────────
;;; build list iteratively to avoid stack overflow

(define (make-big-list n)
  (let ((result '()))
    (while (> n 0)
      (set! result (cons n result))
      (set! n (- n 1)))
    result))

(check-equal "gc-stress-length" (length (make-big-list 100000)) 100000)

;;; ── read-from-string / print-to-string ───────────────────────────────────
;;; print-to-string writes into an existing string buffer

(check-equal "read-from-string" (read-from-string "(+ 1 2)") '(+ 1 2))

(let ((buf (cons-array 64 'string)))
  (print-to-string '(a b c) buf ())
  ;; compare via strcmp: 0 means equal (buf has dim=64 so equal? won't match the literal)
  (check-equal "print-to-string" (strcmp buf "(a b c)") 0))

;;; ── base64 encode/decode roundtrip ──────────────────────────────────────

(let ((original "Hello, SIOD world!"))
  (check-equal "base64-roundtrip"
               (base64decode (base64encode original))
               original))

;;; ── summary ──────────────────────────────────────────────────────────────

(writes nil "\n")
(writes nil "Results: " pass-count " passed, " fail-count " failed\n")
(if (> fail-count 0)
    (error "test-suite" "failures detected"))
