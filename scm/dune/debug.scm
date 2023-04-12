(define *mibl-debugging* #f)

(define-expansion* (mibl-trace-entry hdr msg (color ublue) (test #f))
  (if *mibl-debugging*
      `(if ,test
           (format #t "~A: ~A~%" (,color ,hdr) ,msg)
           (if ,(eq? (symbol->value '*mibl-debug-s7*) #t)
                (format #t "~A: ~A~%" (,color ,hdr) ,msg)
                (values)))
      (values)))

(define-expansion* (mibl-trace hdr msg (color blue) (test #f))
  (if *mibl-debugging*
      `(if ,test
           (format #t "~A: ~A~%" (,color ,hdr) ,msg)
           (if ,(eq? (symbol->value '*mibl-debug-s7*) #t)
               (format #t "~A: ~A~%" (,color ,hdr) ,msg)
               (values)))
      (values)))

(define-expansion* (mibl-trace-let hdr msg (color blue) (test #f))
  (if *mibl-debugging*
      `(_ (if ,test
              (format #t "~A: ~A~%" (,color ,hdr) ,msg)
              (if ,(eq? (symbol->value '*mibl-debug-s7*) #t)
                  (format #t "~A: ~A~%" (,color ,hdr) ,msg)
               '())))
      (values)))

  ;; (if (truthy? test)
  ;;     (if (eq? (symbol->value (car test)) #t)
  ;;         `(_ (format #t "~A: ~A~%" (blue ,hdr) ,msg))
  ;;         '(_ #f))
  ;;     (if (eq? (symbol->value '*mibl-debug-s7*) #t)
  ;;         `(_ (format #t "~A: ~A~%" (blue ,hdr) ,msg))
  ;;         '(_ #f))))

(define (debug-print-stacktrace)
  (format #t "STACKTRACE:\n~A\n" (stacktrace)))

(define (mibl-debug-print-exports-table ws)
  (format #t "~A: ~A~%" (ublue "debug-print-exports-table") ws)
  (let* ((@ws (assoc-val ws *mibl-project*))
         (exports (car (assoc-val :exports @ws)))
         (keys (sort! (hash-table-keys exports) sym<?)))
    (format #t "~A:~%" (ured "exports table"))
    (for-each (lambda (k)
                (format #t " ~A => ~A~%" k (exports k)))
              keys)))
;; (format #t "~A: ~A~%" (red "exports keys") (hash-table-keys exports))
;; (format #t "~A: ~A~%" (red "exports table") exports)))

(define (mibl-debug-print-filegroups ws)
  (format #t "~A: ~A~%" (ublue "debug-print-filegroups") ws)
  (let* ((@ws (assoc-val ws *mibl-project*))
         (filegroups (car (assoc-val :filegroups @ws)))
         (keys (sort! (hash-table-keys filegroups) string<?)))
    ;; (format #t "~A:~%" (red "filegroups table"))
    (for-each (lambda (k)
                (format #t " ~A => ~A~%" k (filegroups k)))
              keys)))

(define (mibl-debug-print-pkgs ws)
  (mibl-pretty-print (assoc-val ws *mibl-project*))
  (newline))

(define (mibl-debug-print-pkg pkg)
  (format #t "~A: ~A~%" (ublue "debug-print-pkg") pkg)
  (let* ((@ws (assoc-val :@ *mibl-project*))
         (pkgs (assoc-val :pkgs @ws))
         (the-pkg (hash-table-ref (car pkgs) pkg)))
    ;;(format #t " ~A: ~A~%" (green "printing pkg") the-pkg)
    (mibl-pretty-print the-pkg)))

(define (mibl-debug-print-project)
  (if *mibl-show-pkg*
      (mibl-debug-print-pkg *mibl-show-pkg*)
      (mibl-pretty-print *mibl-project*))
  (newline))

(define (Xmibl-debug-print-pkgs ws)
  ;; (if *mibl-debug-debug*
  ;;     (format #t "~A~%" (bgred "PKG DUMP")))
  (let* ((@ws (assoc-val ws *mibl-project*))
         (pkgs (car (assoc-val :pkgs @ws)))
         ;; (_ (format #t "~A: ~A~%" (red "pkgs") pkgs))
         (pkg-paths (hash-table-keys pkgs))
         (pkg-paths (sort! pkg-paths string<?))
         )
    (format #t "WS name: ~A~%" (assoc-val :name @ws))
    (format #t "WS path: ~A~%" (assoc-val :path @ws))
    (if *mibl-debug-s7*
        (begin
          (format #t "~A: ~A ~A~%" (bggreen "workspace") (assoc :name @ws) (assoc :path @ws))
          (format #t "~A: ~A~%" (green "*mibl-dump-pkgs*") *mibl-dump-pkgs*)
          (format #t "~A: ~A~%" (green "pkg-paths") pkg-paths)))
    (for-each (lambda (k)
                (let ((pkg (hash-table-ref pkgs k)))
                  ;; (if *mibl-debug-s7*
                  ;;     (begin
                  ;;       (format #t "~A: ~A~%" (green "k") k)
                  ;;       (format #t "~A: ~A~%" (green "pkg") pkg)))
                  (if (or (null? *mibl-dump-pkgs*)
                          (member k *mibl-dump-pkgs*))
                      (begin
                        (format #t "~%~A: ~A~%" (bggreen "Package") (green k)) ;; (assoc-val :pkg-path pkg))
                        ;; (format #t "~A: ~A~%" (green "pkg") pkg) ;; (assoc-val :pkg-path pkg))
                        ;; (for-each (lambda (fld)
                        ;;             (format #t "~A: ~A~%" (ugreen "fld") (car fld)))
                        ;;           pkg)
                        (if-let ((dune (assoc-val 'dune pkg)))
                                (format #t "~A: ~A~%" (ugreen "dune") dune))
                        (if-let ((opams (assoc-val :opam pkg)))
                                (begin
                                  (format #t "~A:~%" (ugreen "opams"))
                                  (for-each (lambda (opam)
                                              (format #t "  ~A~%" opam))
                                            opams)))
                        (if-let ((ms (assoc-val :modules pkg)))
                                (for-each (lambda (m)
                                            (format #t "~A: ~A~%" (ugreen "pkg-module") m))
                                          ms)
                                (format #t "~A: ~A~%" (ugreen "pkg-modules") ms))
                        (format #t "~A:~%" (ugreen "pkg-structures") )
                        (if-let ((ss (assoc-in '(:structures :static) pkg)))
                                (begin
                                  ;; (format #t "  raw: ~A~%" ss)
                                  (for-each (lambda (s)
                                              (format #t "  ~A: ~A~%" (ugreen "static") s))
                                            (cdr ss)))
                                (format #t "  ~A: ~A~%" (ugreen "statics") ss))
                        (if-let ((ss (assoc-in '(:structures :dynamic) pkg)))
                                (for-each (lambda (s)
                                            (format #t "  ~A: ~A~%" (ugreen "dynamic") s))
                                          (cdr ss))
                                (format #t "  ~A: ~A~%" (ugreen "dynamics") ss))
                        ;; (format #t "~A: ~A~%" (ugreen "pkg-structures") (assoc-val :structures pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-signatures") (assoc-val :signatures pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-lex") (assoc-val :lex pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-yacc") (assoc-val :yacc pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-mllib") (assoc-val :mllib pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-cppo") (assoc-val :cppo pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-cc-hdrs") (assoc-val :cc-hdrs pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-cc-srcs") (assoc-val :cc-srcs pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-ppx") (assoc-val :shared-ppx pkg))
                        (format #t "~A: ~A~%" (ugreen "pkg-files") (assoc-val :files pkg))
                        (if-let ((dune (assoc :mibl pkg)))
                                (for-each (lambda (stanza)
                                            (format #t "~A: ~A~%" (ucyan "stanza") stanza))
                                          (cdr dune)))))))
              (sort! (hash-table-keys pkgs) string<?))
    pkgs))

