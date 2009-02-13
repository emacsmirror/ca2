;; based on company-mode.el, auto-complete.el and completion methods 
;; found on emacswiki


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; dabbrev ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
(defun ca-dabbrev-completion-func (prefix)
  "A wrapper for dabbrev that returns a list of expansion of
  PREFIX ordered in the same way dabbrev-expand find expansions.
  First, expansions from the current point and up to the beginning
  of the buffer is listed. Second, the expansions from the current
  point and down to the bottom of the buffer is listed. Last,
  expansions in other buffer are listed top-down. The returned
  list has at most MAXNUM elements."
  (dabbrev--reset-global-variables)
  (let ((all-expansions nil)
	(i 0)
	(j 0)
	(ignore-case nil)
	expansion)
    ;; Search backward until we hit another buffer or reach max num
    (save-excursion
      (while (and (< i 20)
		  (setq expansion (dabbrev--find-expansion 
				   prefix 1 ignore-case))
		  (not dabbrev--last-buffer))
	(setq all-expansions (nconc all-expansions (list expansion)))
	(setq i (+ i 1))))
    ;; If last expansion was found in another buffer, remove of it from the
    ;; dabbrev-internal list of found expansions so we can find it when we
    ;; are supposed to search other buffers.
    (when (and expansion dabbrev--last-buffer)
      (setq dabbrev--last-table (delete expansion dabbrev--last-table)))
    ;; Reset to prepeare for a new search
    (let ((table dabbrev--last-table))
      (dabbrev--reset-global-variables)
      (setq dabbrev--last-table table))
    ;; Search forward in current buffer and after that in other buffers
    (save-excursion
      (while
	  (and (< j 20)
	       (setq expansion (dabbrev--find-expansion 
				prefix -1 ignore-case)))
	(setq all-expansions (nconc all-expansions (list expansion)))
	(setq j (+ i j))))
    all-expansions))

(defvar ca-dabbrev-source
  '((candidates . ca-dabbrev-completion-func)
    (limit      . 1)
    (sorted     . t)
    (name       . "dabbrev"))
  "ca2+ dabbrev source")


;; (defun ca-dabbrev-completion-func (prefix)
;;   (require 'dabbrev)
;;   (let ((dabbrev-check-other-buffers))
;;     (dabbrev--reset-global-variables)
;;     (dabbrev--find-all-expansions prefix nil)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; filename ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ca-file-name-completion-func (prefix)
  (let ((dir (file-name-directory prefix)))
    (ignore-errors
      (mapcar (lambda (file) (concat dir file))
              (remove-if (lambda (file) (or (equal file "../")
                                            (equal file "./")))
                         (file-name-all-completions
                          (file-name-nondirectory prefix) dir))))))


(defvar ca-filename-source
  '((candidates . ca-file-name-completion-func)
    (decider    . filename)
    (limit      . 1)   ;; minimum prefix length to find completion
    (separator  . "/") ;; truncate candidates shown in popup
                       ;; before last position of separator 
    (continue   . t)   ;; find new completions after expansion 
    (sorted     . t)
    (name       . "filename"))
  "ca2+ filename source")



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; lisp symbols ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ca-obarray-completion-func (prefix)
  (all-completions prefix obarray))


(defvar ca-lisp-source
  '((candidates . ca-obarray-completion-func)
    (limit      . 1)
    (sorted     . nil)
    ;;(separator  . "-")
    (name       . "elisp"))
  "ca2+ lisp symbol source")



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; gtags ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'gtags)

(defun gtags-completion-list (prefix)
  (let ((option "-c")
	(prev-buffer (current-buffer))
	(all-expansions nil)
	expansion)
    (set-buffer (generate-new-buffer "*Completions*"))
    (call-process "global" nil t nil option prefix)
    (goto-char (point-min))
    (while (looking-at gtags-symbol-regexp)
      (setq expansion (gtags-match-string 0))
      (setq all-expansions (cons expansion all-expansions))
      (forward-line))
    (kill-buffer (current-buffer))
    ;; recover current buffer
    (set-buffer prev-buffer)
    all-expansions))

(defun ca-gtags-completion-func (prefix)
    (gtags-completion-list prefix))


(defvar ca-gtags-source
  '((candidates . ca-gtags-completion-func)
    (limit      . 1)
    (sorted     . nil)
    (name       . "gtags"))
  "ca2+ gtags source")



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; yasnippet ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; taken from auto-complete.el

(require 'yasnippet)

(defun ca-yasnippet-candidate-1 (table)
  (let ((hashtab (yas/snippet-table-hash table))
        (parent (yas/snippet-table-parent table))
	(regex (concat "^" prefix))
        cands)
    (maphash (lambda (key value)
	       (if (string-match regex key)
		   (push (cons key (yas/template-name (cdar value))) 
			 cands)))
             hashtab)
    (if parent
	(append cands (ca-yasnippet-candidate-1 parent))
      cands)))


(defun ca-yasnippet-candidate (prefix)
  (let ((table (yas/snippet-table major-mode)))
    (if table
	(ca-yasnippet-candidate-1 table))))


(defvar ca-yasnippet-source
  '((candidates . ca-yasnippet-candidate)
    (action     . yas/expand)
    (limit      . 1)
    (sorted     . t)
    (name       . "yasnippet"))
  "ca2+ yasnippet source")



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; install sources ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; sources are pushed, so load lower priority sources first

;; general sources
(ca-add-completion-source
 'otherwise ca-filename-source)

(ca-add-completion-source
 'otherwise ca-dabbrev-source)


(dolist (mode '(c++-mode c-mode java-mode))
  (ca-add-completion-source
   mode ca-gtags-source))

(dolist (mode '(emacs-lisp-mode lisp-interaction-mode))
  (ca-add-completion-source
   mode ca-lisp-source))

(dolist (mode '(emacs-lisp-mode lisp-interaction-mode
				c++-mode c-mode java-mode))
  (ca-add-completion-source
   mode ca-yasnippet-source))



(dolist (hook '(emacs-lisp-mode-hook 
		lisp-mode-hook 
		lisp-interaction-mode-hook
		c-mode-hook 
		c++-mode-hook
		java-mode-hook))
  (add-hook hook '(lambda() 
		    (ca-mode 1))))

;;(ca-clear-completion-sources)

(provide 'ca2+sources)