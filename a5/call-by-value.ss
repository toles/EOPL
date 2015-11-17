#lang racket

(define value-of
  (lambda (exp env)
    (match exp
      [(? boolean? bool) bool]
      [(? number? num)    num]
      [(? symbol? sym) (apply-env env sym)]
      [`(zero? ,n)  (zero? (value-of n env))]
      [`(sub1 ,n) (sub1 (value-of n env))]
      [`(* ,n1 ,n2) (* (value-of n1 env) (value-of n2 env))]
      [`(let ([,id* ,val*] ...) ,body)
       (letrec ([loop (lambda (ids vals body env)
                        (if (null? (cdr ids))
                            (value-of body (extend-env (car ids) (value-of (car vals) env) env))
                            (loop (cdr ids) (cdr vals) body (extend-env (car ids) (value-of (car vals) env) env))))])
         (loop id* val* body env))]
      [`(if ,test ,conseq ,alt) (if (value-of test env)
                                    (value-of conseq env)
                                    (value-of alt env))]
      [`(begin2 ,e1 ,e2) (begin (value-of e1 env) (value-of e2 env))]
      [`(random ,n) (random (value-of n env))]
      [`(lambda (,x) ,body) (closure x body env)]
      [`(set! ,id ,val) (env-set! env id val)]
      [`(,rator ,rand) (apply-closure (value-of rator env)
                                      (value-of rand env))])))

(define empty-env
  (lambda ()
    '()))

(define extend-env
  (lambda  (id arg old-env)
    (cons (vector id arg) old-env)))


(define get-id
  (lambda (vec)
    (vector-ref vec 0)))

(define get-value
  (lambda (vec)
    (vector-ref vec 1)))

(define apply-env
  (lambda (env sym)
    (cond [(null? env) (error "unbound var" sym)]
          [(equal? (get-id (car env)) sym) (get-value (car env))]
          [else
           (apply-env (cdr env) sym)])))

(define env-set!
  (lambda (env sym new-val)
     (cond [(null? env) (error "unbound var" sym)]
           [(equal? (get-id (car env)) sym) (vector-set! (car env) 1 new-val)]
           [else
            (apply-env (cdr env) sym)])))


(define closure
  (lambda (param body env)
    (list param body env)))

(define apply-closure
  (lambda (proc arg)
    (let ([id (car proc)]
          [body (cadr proc)]
          [env (caddr proc)])
      (value-of body (extend-env id arg env)))))


(define run
  (lambda (exp)
    (value-of exp (empty-env))))

(run '((lambda (x) (begin2 (set! x #t)
                         (if x 3 5))) #f))
        
   