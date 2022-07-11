;; (format #t "loading modules.scm\n")

;; mibl/dune/modules.scm

(define (filename->module-assoc filename)
  ;; (format #t "filename->module-assoc ~A\n" filename)
  (let* ((ext (filename-extension filename))
         (pname (principal-name filename))
         (mname (normalize-module-name pname)))
    ;; (format #t "mname: ~A\n" mname)
    (let ((a
           (cond
            ((string=? ext ".mli") (cons mname
                                         (list (list :mli filename))))
            ((string=? ext ".ml") (cons mname
                                        (list (list :ml filename))))
            (else #t))))
      ;; (format #t "f->m result: ~A" a)
      a)))

;; (define indirect-module-dep?
(define module-is-generated?
  (let ((+documentation+ "True if module name does *not* match a source file name."))
    (lambda (module srcfiles)
      ;; (format #t "module-is-generated? ~A : ~A\n" module srcfiles)
      (let recur ((srcfiles srcfiles))
        (if (null? srcfiles)
            #t
            (let* ((m (if (symbol? module) (symbol->string module)
                          (copy module)))
                   (bn (bname (car srcfiles))))

              (if (string=? m bn)
                  #f
                  (begin
                    (string-set! m 0 (char-downcase (string-ref m 0)))
                    (if (string=? m bn)
                        #f
                        (recur (cdr srcfiles)))))))))))

;; modules-assoc:
;;   (modules (:static (A (:ml "a.ml")) (:dynamic (B (:ml "b.ml")))))
;; (define (expand-std-modules modules-spec pkg-modules)
(define get-module-names
  (let ((+documentation+ "Returns module names from modules-assoc, which has the form ((:static (A (:ml a.ml) (:mli a.mli)...) (:dynamic ...))")
        (+signature+ '(get-module-names modules-alist)))
    (lambda (modules-alist)
      (format #t "get-module-names: ~A\n" modules-alist)
      (if modules-alist
          (let* ((statics (assoc-val :static modules-alist))
                 ;; (_ (format #t "statics: ~A\n" statics))
                 (dynamics (assoc-val :dynamic modules-alist))
                 ;; (_ (format #t "dynamics: ~A\n" dynamics))
                 (both (map first (append statics dynamics)))
                 )
            ;; (format #t "both: ~A\n" both)
            both)
          '()))))

;;;;; expand dune constant ':standard' for modules
;; e.g.
;; src/proto_alpha/lib_parmeters: (modules :standard \ gen)
;; lib_client_base:: (modules (:standard bip39_english))

;; (define (expand-std-modules modules srcfiles)

(define (resolve-gentargets gentargets sigs structs)
  (format #t "resolve-gentargets: ~A\n" gentargets)
  (let ((resolved (map (lambda (f)
                         (format #t "f: ~A\n" f)
                         (let* ((fname (if (symbol? f) (symbol->string f) f))
                                (type (if (eq? 0 (fnmatch "*.mli" fname 0))
                                          :mli :ml))
                                (mname (file-name->module-name fname)))
                           (format #t "mname: ~A\n" mname)
                           (format #t "type: ~A\n" type)
                           (if (eq? type :ml)
                               (if-let ((sigmatch (assoc-in `(:static ,mname)
                                                            sigs)))
                                       (begin
                                         ;; remove from pkg :signatures
                                         (alist-update-in!
                                          sigs `(:static)
                                          (lambda (old)
                                            (format #t "old static: ~A\n"
                                                    old)
                                            (dissoc `(,mname) old)))
                                         `(:_ ,(car sigmatch)))
                                       `(:ml ,mname))
                               (if-let ((structmatch
                                         (assoc-in `(:static ,mname)
                                                   structs)))
                                       (begin
                                         ;; remove from pkg :structures
                                         (alist-update-in!
                                          structs `(:static)
                                          (lambda (old)
                                            (format #t "old static: ~A\n"
                                                    old)
                                            (dissoc `(,mname) old)))
                                         `(:_ ,(car structmatch)))
                                       `(:mli ,mname)))))
                       gentargets)))
    resolved))

;; std-list arg: everything after :standard, e.g. (:standard \ foo)
;; WARNING: the '\' is a symbol, but it does not print as '\,
;; rather it prints as (symbol "\\"); use same to compare, do
;; not compare car to 'symbol, like so:
;; (if (not (null? modules))
;;     (if (equal? (car modules) (symbol "\\"))
;;         (format #t "EXCEPTING ~A\n" (cdr modules))))

;; handling '/': in principle it can go anywhere:
;; (<sets1> \ <sets2>) is how the docs put it.
;; in practice it only seems to be used after :standard
;; e.g. (:standard \ foo) includes all modules except foo
;; also found: (modules (:standard) \ foo)
(define expand-std-modules
  (let ((+documentation+ "expands a ':standard' part of a (modules :standard ...) clause. std-list: the ':standard' clause and any modifiers.  pkg-modules: list of source modules (paired .ml/.mli files), from mibl :modules fld; module-deps: :deps from 'libraries' field and possibly :conditionals (if 'select' is used). :conditionals contains (LHS -> RHS) clauses.")
        (+signature+ '(expand-std-modules std-list pkg-modules module-deps sigs structs)))
    ;; modules-ht)))
    (lambda (std-list pkg-modules sigs structs) ;;  module-deps

      (format #t "~A: ~A\n" (blue "EXPAND-std-modules") std-list)
      (format #t " pkg-modules: ~A\n" pkg-modules)
      ;; (format #t " module-deps: ~A\n" module-deps)
      (format #t " sigs: ~A\n" sigs)
      (format #t " structs: ~A\n" structs)
      (let* ((modifiers (cdr std-list)) ;; car is always :standard
             (pkg-module-names (get-module-names (cdr pkg-modules)))
             (struct-module-names (get-module-names structs))
             (pkg-module-names (if struct-module-names
                                   (append struct-module-names
                                           pkg-module-names)
                                   pkg-module-names))
             (sig-module-names (get-module-names sigs))
             ;; (pkg-module-names (if sig-module-names
             ;;                       (append sig-module-names
             ;;                               pkg-module-names)
             ;;                       pkg-module-names)

             ;; FIXME: encode conditionals in sigs & structs pkg flds
             ;; as :dynamic
             ;; (so we need not pass deps around to expand std modules)

             ;; (conditionals (assoc :conditionals module-deps))
             )
        (format #t "pkg-module-names: ~A\n" pkg-module-names)
        (format #t "sig-module-names: ~A\n" sig-module-names)
        (format #t "modifiers: ~A\n" modifiers)
        ;; (format #t "conditionals: ~A\n" conditionals)
        (if-let ((slash (member (symbol "\\") modifiers)))
                (let* ((exclusions (cdr slash))
                       (exclusions (if (list? (car exclusions))
                                       (car exclusions) exclusions))
                       (exclusions (map normalize-module-name exclusions)))
                  (format #t "exclusions: ~A\n" exclusions)
                  (let ((winnowed (remove-if
                                   list
                                   (lambda (item)
                                     (let ((norm (normalize-module-name item)))
                                       ;; (format #t "item ~A\n" norm)
                                       ;; (format #t "mem? ~A: ~A\n" exclusions
                                       ;;         (member norm exclusions))
                                       (if (member norm exclusions) #t #f)))
                                   pkg-module-names)))
                    ;; returning
                    (values winnowed sigs)))
                ;; else no explicit exclusions, but, select apodoses
                ;; always excluded:
                (values pkg-module-names sig-module-names))
        ))))

;; was (define (modules->modstbl modules srcfiles) ;; lookup_tables.scm
;; expand (modules ...) and convert to (:submodules ...)
;; variants:
;; (modules) - empty, exclude all
;; (modules :standard) == (modules (:standard)) == omitted == include all
;; (modules foo bar) - include just those listed
;; WARNING: :standard cannot be fully expanded until all stanzas in
;; the package have been processed to discover generated files, e.g.
;; rule stanzas may generate files, (expressed by 'target' flds).
;; so rules should be processed first.

;;  expand-modules-fld!
(define modules-fld->submodules-fld
  ;;TODO: direct/indirect distinction. indirect are generated src files
  (let ((+documentation+ "Expand  'modules' field (of library or executable stanzas) and convert to pair of :submodules :subsigs assocs. modules-spec is a '(modules ...)' field from a library stanza; pkg-modules is the list of modules in the package: an alist whose assocs have the form (A (:ml a.ml)(:mli a.mli)), i.e. keys are module names.")
        (+signature+ '(modules-fld->submodules-fld modules-spec pkg-modules sigs structs))) ;;  modules-deps
        ;; modules-ht)))
    (lambda (modules-spec pkg-modules pkg-sigs pkg-structs)
      (format #t "~A\n" (blue "MODULES-FLD->SUBMODULES-FLD"))
      (format #t "modules-spec: ~A\n" modules-spec)
      (format #t "pkg-modules: ~A\n" pkg-modules)
      ;; (format #t "deps: ~A\n" deps)
      (format #t "pkg-sigs: ~A\n" pkg-sigs)
      (format #t "pkg-structs: ~A\n" pkg-structs)
      (if (or pkg-modules pkg-structs)
          (if modules-spec
              (let* ((modules-spec (map normalize-module-name
                                        (cdr modules-spec)))
                     (pkg-module-names (if pkg-modules
                                           (get-module-names
                                            (cdr pkg-modules))
                                           '()))
                     (struct-module-names (get-module-names pkg-structs))
                     (pkg-module-names (if struct-module-names
                                           (append struct-module-names
                                                   pkg-module-names)
                                           pkg-module-names))
                     (sig-module-names (get-module-names pkg-sigs))
                     (_ (format #t "modules-spec:: ~A\n" modules-spec))
                     (tmp (let recur ((modules-spec modules-spec)
                                      (submods '())
                                      (subsigs '()))
                            (format #t "RECUR modules-spec ~A\n" modules-spec)
                            (format #t "  submods: ~A\n" submods)
                            (format #t "  subsigs: ~A\n" subsigs)

                            (cond
                             ((null? modules-spec)
                              (if (null? submods)
                                  (begin
                                    (format #t "null modules-spec\n")
                                    '())
                                  (begin
                                    (format #t "DONE\n")
                                    (list
                                     (cons :submodules submods)
                                     (if (null? subsigs)
                                         '() (cons :subsigs subsigs))))))
                             ;; (reverse submods)

                             ((pair? (car modules-spec))
                              (begin
                                (format #t "(pair? (car modules-spec))\n")
                                ;; e.g. ((:standard)) ?
                                ;; or (modules (:standard) \ foo)
                                ;; or (A B C)
                                ;; just unroll and recur
                                (if (equal? '(:standard) (car modules-spec))
                                    (modules-fld->submodules-fld
                                     (append
                                      (list 'modules :standard) (cdr modules-spec))
                                     pkg-modules
                                     ;; deps
                                     pkg-sigs pkg-structs)
                                    (modules-fld->submodules-fld
                                     (cons
                                      'modules (car modules-spec))
                                     pkg-modules
                                     ;; deps
                                     pkg-sigs
                                     pkg-structs))))

                             ((equal? :standard (car modules-spec))
                              ;; e.g. (modules :standard ...)
                              (begin
                                (format #t "(equal? :standard (car modules-spec))\n")
                                (let-values (((mods-expanded sigs-expanded)
                                              (expand-std-modules
                                                      modules-spec
                                                      pkg-modules
                                                      ;; deps
                                                      pkg-sigs pkg-structs)))
                                  (format #t "mods-expanded: ~A\n"
                                          mods-expanded)
                                  (format #t "sigs-expanded: ~A\n"
                                          sigs-expanded)
                                  (format #t "updated pkg: ~A\n" pkg)
                                  ;; (error 'tmp "tmp")

                                  (list
                                   (cons :submodules (reverse mods-expanded))
                                   (if sigs-expanded
                                       (cons :subsigs
                                             (reverse sigs-expanded))
                                       '())))))

                             ;; inclusions, e.g. (modules a b c)
                             (else
                              (begin
                                (format #t "inclusions: ~A\n" modules-spec)
                                (format #t "pkg-modules: ~A\n" pkg-module-names)
                                (format #t "sig-modules: ~A\n" sig-module-names)
                                (if (member (car modules-spec) pkg-module-names)
                                    (recur (cdr modules-spec)
                                           (cons (car modules-spec) submods)
                                           subsigs)
                                    (if (member (car modules-spec) sig-module-names)
                                        (recur (cdr modules-spec)
                                               submods
                                               (cons (car modules-spec) subsigs))
                                        (error 'bad-arg "included module not in list")))))
                             ) ;; cond
                            ))) ;; recur
                tmp) ;; let*
              ;; no modules-spec - default is all
              (begin
                (format #t "no modules-spec\n")
                (get-module-names (cdr pkg-modules)))
              ) ;; if modules-spec
          ;; else no modules in pkg
          (begin
            (format #t "no pkg-modules, pkg-structs\n")
            '()))
      ) ;; lamda
    ) ;; let
  ) ;; define

;; (define (expand-modules-fld modules srcfiles)
;;   ;; modules:: (modules Test_tezos)
;;   ;; (format #t "  expand-modules-fld: ~A\n" modules)
;;   ;; see also modules->modstbl in dune_stanza_fields.scm
;;   (let* ((modules (cdr modules)))
;;     (if (null? modules)
;;         (values '() '())
;;         ;; (let ((result
;;         (let recur ((modules modules)
;;                     (direct '())
;;                     (indirect '()))
;;           ;; (format #t "ms: ~A; direct: ~A\n" modules direct)
;;           (cond
;;            ((null? modules)
;;             (values direct indirect))

;;            ((equal? :standard (car modules))
;;             (let ((newseq (srcs->module-names srcfiles))) ;;  direct
;;               ;; (format #t "modules :STANDARD ~A\n" newseq)
;;               ;; (format #t "CDRMODS ~A\n" (cdr modules))
;;               (recur (cdr modules) (append newseq direct) indirect)))
;;            ;; (concatenate direct
;;            ;;              (norm-std-modules (cdr modules))))
;;            ((pair? (car modules))
;;             (let-values (((exp gen)
;;                           (recur (car modules) '() '())))
;;               (recur (cdr modules)
;;                      (concatenate exp direct)
;;                      (concatenate gen indirect))))

;;            ((indirect-module-dep? (car modules) srcfiles)
;;             (begin
;;               ;; (format #t "INDIRECT: ~A\n" (car modules))
;;               (recur (cdr modules)
;;                      direct (cons (car modules) indirect))))

;;            (else
;;             (recur (cdr modules)
;;                    (cons (car modules) direct)
;;                    indirect))))
;;         ;;      ))
;;         ;; ;;(format #t "RESULT: ~A\n" result)
;;         ;; (reverse result))
;;         ))
;;   )


;; (format #t "loaded modules.scm\n")
