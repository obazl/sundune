(define (-fixup-progn-cmd! ws c targets deps)
  (format #t "~A: ~A\n" (ublue "-fixup-progn-cmd!") c)
  c)

(define (-module->filename m pkg)
  (format #t "~A: ~A~%" (blue "-module->filename") m)
  (let ((pkg-modules (assoc-val :modules pkg))
        (pkg-structs (assoc-val :structures pkg)))
    (format #t "~A: ~A~%" (white "pkg-modules") pkg-modules)
    (format #t "~A: ~A~%" (white "pkg-structs") pkg-structs))
  "mytest.ml")

(define (-resolve-module-deps m stanza pkg)
  (format #t "~A: ~A~%" (blue "-resolve-module-deps") m)
  (format #t "~A: ~A~%" (white "stanza") stanza)
  (let* ((m-fname (-module->filename m pkg))
         (pkg-path (car (assoc-val :pkg-path pkg)))
         (cmd (format #f "ocamldep -modules ~A/~A" pkg-path m-fname))
         (_ (format #t "~A: ~A~%" (green "cmd") cmd))
         (ocamldeps
          (system cmd #t)))
    (format #t "~A: '~A'~%" (red "ocamldeps") ocamldeps)
    ;; search pkg-local modules for dep
    ;; else search exports table for dep
    ;; else assume opam
    (list m '(:deps (:foo :bar)))))

(define (-fixup-std-dep-form dep exports)
  (case (last dep)
    ((::import)
     ;; (if (eq? ::import (last dep))
     (let ((exp (hash-table-ref exports
                                (car dep))))
       (format #t "~A: ~A~%" (ured "XP") exp)
       (if exp
           (let* ((pkg (assoc-val :pkg exp))
                  (_ (format #t "~A: ~A~%" (ured "pkg") pkg))
                  (tgt (assoc-val :tgt exp))
                  (_ (format #t "~A: ~A~%" (ured "tgt") tgt)))
             (cons (car dep) exp))
           dep)))
    ((::pkg)
     ;; side-effect: update filegroups table
     ;; FIXME: instead, add :fg dep?
     (format #t "~A: ~A~%" (yellow "export keys")
             (hash-table-keys exports))
     (format #t "~A: ~A~%" (yellow "exports")
             exports)
     (let* ((exp (hash-table-ref exports
                                 (car dep)))
            (_ (format #t "~A: ~A~%" (yellow "exp") exp))
            (pkg (assoc-val :pkg exp))
            )
       (format #t "~A: ~A~%" (yellow "pkg") pkg)
       (update-filegroups-table! ;; ws pkg-path tgt pattern
        ws ;; (car (assoc-val :name ws))
        pkg ::all "*")
       (cons (car dep)
             (list (car exp)
                   (cons :tgt "__all__")))))
    (else dep)))

;; FIXME: rename
(define (-fixup-stanza! ws pkg stanza)
  (format #t "~A: ~A\n" (ublue "-fixup-stanza!") stanza)
  (let* ((exports (car (assoc-val :exports ws)))
         (stanza-alist (cdr stanza)))
    (format #t "~A: ~A\n" (green "exports tbl") exports)
    (case (car stanza)

      ((:executable :test)
       (format #t "~A: ~A~%" (magenta "fixup") (car stanza))
       ;; FIXME: also handle :dynamic
       (let ((modules (assoc-in '(:compile :manifest :modules) stanza-alist))
             (deps (assoc-in '(:compile :deps :fixed) stanza-alist)))
         (format #t "test compile modules: ~A~%" modules)
         (format #t "test compile deps: ~A~%" deps)
         (if deps ;; (not (null? deps))
             (let ((new (map (lambda (dep)
                               ;; (format #t "~A: ~A\n" (uyellow "dep") dep)
                               (let ((exp (hash-table-ref exports dep)))
                                 ;; (format #t "~A: ~A\n" (uyellow "ht val") exp)
                                 (if exp
                                     (string->symbol (format #f "//~A:~A" exp dep))
                                     ;; assume opam label:
                                     (string->symbol (format #f "@~A//:~A" dep dep)))))
                             (cdr deps))))
               (set-cdr! deps new)
               (set-car! deps :resolved)))
         ;; (if modules
         ;;     (let ((new (map (lambda (m)
         ;;                       (format #t "module: ~A\n" m)
         ;;                       (let ((exp (hash-table-ref exports m)))
         ;;                         (format #t "importing: ~A\n" exp)
         ;;                         (if exp
         ;;                             (format #f "//~A:~A" exp m)
         ;;                             (-resolve-module-deps m stanza pkg))))
         ;;                     (cdr modules))))
         ;;       (set-cdr! modules new)))
         (format #t "~A: ~A~%" (bgred "deps") deps)
         )
       ;; (error 'fixme "STOP labels")
       )

      ((:rule)
       (format #t "~A: ~A~%" (magenta "fixup :rule") stanza-alist)
       (let* ((targets (assoc-val :outputs stanza-alist))
              (_ (format #t "targets: ~A~%" targets))
              (deps (if-let ((deps (assoc :deps stanza-alist)))
                            ;; (if (null? deps) '() (car deps))
                            deps
                            '()))
              (_ (format #t "deps: ~A~%" deps))
              (action (if-let ((action (assoc-val :actions stanza-alist)))
                              action
                              (if-let ((action
                                        (assoc-val :progn stanza-alist)))
                                      action
                                      (error 'bad-action "unexpected action in :rule"))))
              (_ (format #t "action: ~A~%" action))
              (tool (assoc-in '(:actions :cmd :tool) stanza-alist)))
         (format #t "Tool: ~A~%" tool)
         (format #t "Action: ~A~%" action)
         (format #t "stanza-alist: ~A~%" stanza-alist)

         ;; fixup-deps
         ;; (if-let ((deps (if-let ((deps (assoc :deps stanza-alist)))
         ;;                     ;; (if (null? deps) '() (car deps))
         ;;                     deps #f)))
         (if deps
             (begin
               (format #t "~A: ~A~%" (ured "resolving dep labels") deps)
               (let ((exports (car (assoc-val :exports ws)))
                     (fixdeps
                      (map (lambda (dep)
                             (format #t "~A: ~A~%" (uwhite "fixup dep") dep)
                             (if (eq? (car dep) ::tools)
                                 (begin
                                   (format #t "~A: ~A~%" (bgred "::TOOLS") (caadr dep))
                                   (if  (eq? ::import (cdadr dep))
                                        (begin
                                          (format #t "~A~%" (bgred "IMPORT TOOL"))
                                          (if-let ((import (hash-table-ref exports (caadr dep))))
                                                  (begin
                                                    (format #t "~A: ~A~%" (bgred "importing") import)
                                                    (cons ::tools
                                                          (list (cons (caadr dep)
                                                                      (list (assoc :pkg import)
                                                                            (assoc :tgt import))
                                                                      ;; (format #f "//~A:~A"
                                                                      ;;         (assoc-val :pkg import)
                                                                      ;;         (assoc-val :tgt import))
                                                                      )))
                                                    )
                                                  (begin
                                                    (format #t "~A: ~A~%" (red "no import for") (caadr dep))
                                                    )))
                                        ;; else treat it just like a std dep
                                        (-fixup-std-dep-form dep exports)))
                                 ;; else std dep form: (:foo (:pkg...)(:tgt...))
                                 (-fixup-std-dep-form dep exports)))
                           (cdr deps))))
                 (format #t "~A: ~A~%" (ured "fixed-up deps") fixdeps)
                 (set-cdr! deps fixdeps))))
                 ;; (format #t "~A: ~A~%" (ured "reset deps") deps)

         ;; :actions is always a list of cmd; for progn, more than one
         (if (assoc :actions stanza-alist)
             (begin
               (for-each (lambda (c)
                           (format #t "PROGN cmd: ~A~%" c)
                           (-fixup-progn-cmd! ws c targets deps))
                         action))
             ;; else? actions always have a :cmd?
             (begin
               (format #t "rule action: ~A~%" action)
               (format #t "rule tool: ~A~%" tool)
               (format #t "rule targets: ~A~%" targets)
               (format #t "rule deps: ~A~%" deps)
               (error 'unhandled action "unhandled action")
               ;; (if-let ((tool-label (hash-table-ref exports (cadr tool))))
               ;;         (let* ((_ (format #t "tool-label: ~A~%" tool-label))
               ;;                (pkg (car (assoc-val :pkg tool-label)))
               ;;                (tgt (car (assoc-val :tgt tool-label)))
               ;;                (label (format #f "//~A:~A" pkg tgt))
               ;;                (_ (format #t "tool-label: ~A\n" tool-label)))
               ;;           (set-cdr! tool (list label)))
               ;;         ;; FIXME: handle deps
               ;;         '())
               ))))

      ((:archive :ns-archive)
       (format #t "~A~%" (magenta "fixup :archive, :ns-archive"))
       ;; (let ((deps (assoc-val :deps stanza-alist)))
       ;;   (format #t "archive deps: ~A~%" deps)))
       (let* ((deps (if-let ((deps (assoc-in '(:deps :fixed) stanza-alist)))
                            deps #f))
              (_ (format #t "deps: ~A~%" deps))
              )
         (if deps
             (begin
               (format #t "~A: ~A~%" (ured "resolving dep labels") deps)
               (let ((exports (car (assoc-val :exports ws)))
                     (fixdeps
                      (map (lambda (dep)
                             (format #t "~A: ~A~%" (uwhite "fixup dep") dep)
                             (cond
                              ((list? dep)
                                 ;; std dep form: (:foo (:pkg...)(:tgt...))
                               (-fixup-std-dep-form dep exports))
                              ((symbol? dep)
                               (string->symbol (format #f "@~A//:~A" dep dep)))
                              (else (error 'fixme
                                           (format #f "~A: ~A~%" (bgred "unrecognized :archive dep type") dep)))))
                           (cdr deps))))
                 (format #t "~A: ~A~%" (ured "fixed-up deps") fixdeps)
                 (set-cdr! deps fixdeps)
                 (set-car! deps :resolved))))))

      ;; ((:library)
      ;;  (format #t "~A~%" (magenta "fixup :library"))
      ;;  (let ((manifest (assoc-val :manifest stanza-alist))
      ;;        (deps (assoc-val :deps stanza-alist)))
      ;;    (format #t "library deps: ~A~%" deps)))

      ((:ocamllex :ocamlyacc) (values))
      (else
       (error 'fixme
              (format #t "~A: ~A~%" (bgred "unhandled fixup stanza") stanza))))))

;; updates stanzas
(define resolve-labels!
  (let ((+documentation+ "Map dune target references to bazel labels using exports table.")
        (+signature+ '(resolve-labels! workspace)))
    (lambda (ws)
      (format #t "~A for ws: ~A\n" (blue "resolve-labels!") (assoc :name ws))
              ;; (assoc-val 'name ws))
      (let* ((pkgs (car (assoc-val :pkgs ws)))
             ;; (_ (format #t "PKGS: ~A\n" pkgs))
             (exports (car (assoc-val :exports ws))))
        ;; (format #t "resolving labels for pkgs: ~A\n" (hash-table-keys pkgs))
        ;; (format #t "exports: ~A\n" exports)
        (for-each (lambda (kv)
                    (format #t "resolving pkg: ~A~%" (car kv))
                    ;; (format #t "pkg: ~A~%" (cdr kv))
                    (let ((pkg (cdr kv)))
                      (if-let ((stanzas (assoc-val :dune (cdr kv))))
                              (for-each (lambda (stanza)
                                          (-fixup-stanza! ws pkg stanza)
                                          (format #t "stanza: ~A~%" stanza))
                                        stanzas)))
                    )
                  pkgs)
        ))))

