;; flymake
(require 'flymake)
(setq flymake-no-changes-timeout most-positive-fixnum)
(setq flymake-start-syntax-check-on-newline nil)

(defun flymake-erlang-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy
		     'flymake-create-temp-inplace))
	 (local-file (file-relative-name temp-file
		(file-name-directory buffer-file-name))))
    (list "~/elisp/ecompile.sh" (list local-file))))

(add-to-list 'flymake-allowed-file-name-masks '("\\.erl\\'" flymake-erlang-init))

(defun my-flymake-show-next-error()
    (interactive)
    (flymake-goto-next-error)
    (flymake-display-err-menu-for-current-line) )

(local-set-key "\C-c\C-v" 'my-flymake-show-next-error)

(defun flymake-display-err-minibuffer ()
  "display error in mini buffer"
  (interactive)
  (let* ((line-no (flymake-current-line-no))
         (line-err-info-list (nth 0 (flymake-find-err-info flymake-err-info line-no)))
         (count (length line-err-info-list)))
    (while (> count 0)
      (when line-err-info-list
        (let* ((file (flymake-ler-file (nth (1- count) line-err-info-list)))
               (full-file (flymake-ler-full-file (nth (1- count) line-err-info-list)))
               (text (flymake-ler-text (nth (1- count) line-err-info-list)))
               (line (flymake-ler-line (nth (1- count) line-err-info-list))))
          (message "[%s] %s" line text)))
      (setq count (1- count)))))

(defun display-ct-err-minibuffer()
  (interactive)
  (let* ((line-no (line-number-at-pos))
	 (err-txt nil))
;;    (and erlang-ct-errors
    (and 1
	 (progn
	   (setq err-txt  (ct-line-no-overlay-text (line-beginning-position) (line-end-position)))
	   (and err-txt (message "[%s] %s" line-no err-txt))))))

(defun show-error()
  (interactive)
  (flymake-display-err-minibuffer)
  (display-ct-err-minibuffer))
 
(defadvice flymake-goto-next-error (after display-message activate compile)
  "goto next error"
  (flymake-display-err-minibuffer))

(defadvice flymake-goto-prev-error (after display-message activate compile)
  "goto prev error"
  (flymake-display-err-minibuffer))

(defadvice flymake-mode (before post-command-stuff activate compile)
  " post command hook "
  (set (make-local-variable 'post-command-hook)
       (add-hook 'post-command-hook 'show-error)))

;; post-command-hook 
(define-key global-map (kbd "C-c d") 'flymake-display-err-minibuffer)
;;(global-set-key [f3] 'flymake-display-err-menu-for-current-line)
(global-set-key [f3] 'flymake-goto-next-error)

(provide 'extend-flymake)