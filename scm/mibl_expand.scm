(if *mibl-debug-s7-loads*
    (format #t "loading mibl_expand.scm~%"))

(load "mibl_debug.scm")

;;(load "mibl.scm")

;;(require mibl.scm)

(load "libmibl.scm")

;; (define* (-main root-path pkg-path)
;;   (format #t "mibl_expand: -main routine\n"))

;;;;;;;;;;;;;;;;;;;;;;;;;
(define (-mibl-load-project root path)
  (if *mibl-debug-all*
      (begin
        (format #t "~A: ~A (~A)~%" (blue "-mibl-load-project") path (type-of path))
        (format #t "pwd: ~A~%" (pwd))))
  (let* ((_wss  (if path (mibl-load-project #|(pwd)|# path)
                    (mibl-load-project)))
         ;; (_ (format #t "~A: ~A~%" (green "_wss") _wss))
         )
    _wss))

;; (define (-resolve-labels ws)
;;   (expand-lib-deps! (assoc-val ws *mibl-project*)))

;; (define (-miblarkize ws)
;;   (let* ((@ws (assoc-val ws *mibl-project*))
;;          (pkgs (car (assoc-val :pkgs @ws))))

;;     (for-each (lambda (kv)
;;                 (format #t "~A: ~A~%" (blue "miblarkizing") kv)
;;                 ;; dir may have dune-project but no dune file:
;;                 (if (not (null? (cdr kv)))
;;                     (mibl-pkg->miblark (cdr kv)))
;;                 )
;;               pkgs)))

(define* (-main root-path ws-path)
  (mibl-trace-entry "mibl_expand" "-main")
  ;; (format #t "-main (mibl_expand.scm)\n")
  ;; (format #t "ws path: ~A\n" ws-path)
  ;; (let ((_ (values))) asdf asdf )
  (load "libmibl.scm")
  (if *mibl-clean-mibl*
      (mibl-clean-mibl)
      (call-with-exit (lambda (return)
                        (mibl:parsetree->miblx ;; in libmibl.scm
                         (lambda () ;; our return thunk
                           (if *mibl-show-mibl*
                               (begin
                                 (mibl-debug-print-project)
                                 (flush-output-port))
                               (if *mibl-show-pkg*
                                   (mibl-debug-print-pkg)))
                           ;; (if (not *mibl-quiet*)
                           ;;     (format #t "~A: mibl returning...~%" (green "INFO")))
                           (return))
                         ;; root-path ws-path
                         )))))

(if *mibl-debug-s7-loads*
    (format #t "loaded mibl_expand.scm~%"))

