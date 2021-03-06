
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; install sources ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ca2+)
(require 'ca2+sources)
(require 'ca2+source-semantic)
(require 'ca2+ac)

;; Options what tab should preferably do.
;; just uncomment the preferred method:

;; default: tab cycles to next source
(define-key ca-active-map [tab] 'ca-next-source)

;; tab cycles to next candidate
;;(define-key ca-active-map [tab] 'ca-cycle)

;; tab expands current candidate
;;(define-key ca-active-map [tab] 'ca-expand-top)

;; tab expands common part, after that it expands the 
;; current candidate to the next word boundary 
;; when only one candidate is left tab will insert 
;; that candidate 
;; (define-key ca-active-map [tab] 'ca-expand-common)

;; when rebinding tab you'll need another binding for 
;; cycling sources. e.g.:
;; (define-key ca-active-map "\M-h" 'ca-next-source)

;; if the source has an 'continue' action, like e.g. filename-source
;; to continue completion after inserting a directory name, or
;; semantic-source to continue with completion of member variables
;; resp. inserting a function argument template these will be triggered
;; by expand-and-continue
(define-key ca-active-map [(C return)] 'ca-expand-and-continue)


(ca-clear-completion-sources)

;;;; MODE SPECIFIC sources
;; sources are pushed on the list: load lower priority sources first

;;;; ELISP source:
(ca-add-source ca-source-lisp
	       '(emacs-lisp-mode 
		 lisp-interaction-mode))

;;;; GTAGS source:
;; complete prefixes with tags found in gtags tags table
(eval-after-load 'gtags
  '(progn 
     (ca-add-source ca-source-gtags
		    '(c++-mode c-mode java-mode))))



;;;; SEMANTIC source:
;;(eval-after-load 'semantic
;; '(progn 
     ;;(require 'semantic-ia)

     ;; Enable experimental, but (hopefully) faster version.  
     ;; Search results for a desired type are also sorted by
     ;; reachability so vars having the desired type come first, then
     ;; vars that have members from which desired type is reachable.
     (require 'ca2+semantic)

     ;; complete prefix with tags found in semantics tags table
     ;; (ca-add-source ca-source-semantic-tags
     ;; 		    '(c++-mode c-mode))
     
     ;;;; this source tries to figure out from context what preferred
     ;; candidates are. e.g: for 'int bla =' it finds vars and
     ;; functions that have int as type, same within function
     ;; arguments. it also sorts candidates first that have members
     ;; from which the desired type is reachable (when using
     ;; ca2+semantic). Use C-ret (ca-expand-and-continue) to complete
     ;; a function and insert argument templates for funtions or to
     ;; complete a variable and insert '.' resp. '->' and continue with
     ;; completing its members.
 (ca-add-source ca-source-semantic-context
 		    '(c++-mode c-mode java-mode jde-mode))
     
     ;;;; OMNICOMPLETION:
     ;; uncomment things below for omnicompletion. though you can just
     ;; type [tab] and C-ret to complete current candidate, insert '.' or 
     ;; respectively '->' and show completion menu for members.
     ;;
     ;; (defun ca-semantic-completion (arg)
     ;;   (interactive "p")
     ;;   (self-insert-command arg)
     ;;   (when (and (= arg 1))
     ;; 	 (ca-begin nil ca-source-semantic-context)))
     ;; (defun ca-semantic-c-hook ()
     ;;   (local-set-key "." 'ca-semantic-completion)
     ;;   (local-set-key ">" 'ca-semantic-completion))
     ;; (add-hook 'c-mode-common-hook 'ca-semantic-c-hook)
 ;;   ))

(eval-after-load "pymacs"
  ;; TODO figure out when rope is loaded
  (ca-add-source ca-source-python-rope
		 '(python-mode)))

;;;; GENERAL sources are tried after mode specific ones 
(ca-add-source ca-source-filename 'otherwise)
(ca-add-source ca-source-dabbrev 'otherwise)

;;;; YASNIPPET source:
;; this source show possible completions when a prefix
;; matches more than one yasnippet template

;; it seems that this needs to be set before '(require 'yasnippet)'
;; change this to your liking, but tab would interfere with 
;; completion within yas templates.
;; (defvar yas/next-field-key (kbd "C-f"))
;; (defvar yas/prev-field-key (kbd "C-b"))

;; (eval-after-load 'yasnippet
;;   '(progn
;;      (ca-add-source ca-source-yasnippet 'otherwise)))



(global-ca-mode 1)

(provide 'ca2+init) 

