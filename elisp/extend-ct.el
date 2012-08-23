
(defvar run_ct_error nil
"save ct run error"
)
(defstruct (erlang-ct-err
	    (:constructor nil)
	    (:constructor elang-ct-make-err (file fun  line text)))
  file fun line text)
;;(setq txt "test1_SUITE:t1 failed on line 17")
;;(string-match "\\(.+\\):\\(.+\\) failed on line \\([0-9]+\\)" txt)
(defun parse-ct-error(line1 line2)
  "parse line to get ct error"
  (let* ((file)
	 (line-no)
	 (text))
    (if (string-match "\\(.+\\):\\(.+\\) failed on line \\([0-9]+\\)" line1)
	(progn
	  (setq file (substring  line1 (match-beginning 1) (match-end 1)))
	  (setq fun  (substring  line1 (match-beginning 2) (match-end 2)))
	  (setq line-no (substring  line1 (match-beginning 3) (match-end 3)))
	  (setq text (substring line2 8 (length line2)))
	  (message line-no)
	  (list file fun (string-to-int line-no) text)
	  ))))


(defvar erlang-ct-errors nil
"all errors from ct:run buffers"
)
(defun get-ct-errors()
  (interactive)
  (save-excursion
    (let* ((output)
	   (tmp)
	   (count 0))
      (progn
	(set-buffer inferior-erlang-buffer)
	;; (setq output (ct-split-output(buffer-string)))
	(setq output (split-string (buffer-string) "[\r\n]"))
	;;(message (buffer-string))
	(while (< count (- (length output) 2))
	  (setq tmp (parse-ct-error (nth count output) (nth (+ 1 count) output)))
	  (and tmp
	      (setq erlang-ct-errors (cons tmp erlang-ct-errors)))
	  ;; (setq erlang-ct-errors (append erlang-ct-errors (parse-ct-error (nth 0 output) (nth 1 output))))
	  (setq count (+ 1 count)))
	(message "lenth or err %d" (length erlang-ct-errors))))))

(defun ct-split-output(output)
    "split output into lines, return last one as residual if it does not end with newline char. Returns ((lines) residual)"
	(when (and output (> (length output) 0))
        (let* ((lines (split-string output "[\r\n]+"))
			   (complete (equal "\n" (char-to-string (aref output (1- (length output))))))
	    	   (residual nil))
		    (when (not complete)
				(setq residual (car (last lines)))
			    (setq lines (butlast lines))
			)
 	        (list lines residual)
		)
	)
)

;;;;;;;;;;;;;;;;highlight error inf buffer,learn form flymake

(defun ct-overlay-p(ov)
     "Determine whether overlay was created by flymake"
     (and (overlayp ov) (overlay-get ov 'ct-overlay))
)

(defun ct-make-overlay(beg end tooltip-text face mouse-face line-no)
    "Allocate a flymake overlay in range beg end"
	(when (not (ct-region-has-ct-overlays beg end))
		(let ((ov (make-overlay beg end nil t t)))
			(overlay-put ov 'face           face)
			(overlay-put ov 'mouse-face     mouse-face)
			(overlay-put ov 'help-echo      tooltip-text)
			(overlay-put ov 'ct-overlay  t)
			(overlay-put ov 'priority 100)
			(overlay-put ov 'line-no line-no)
			;+(flymake-log 3 "created overlay %s" ov)
			ov
		)
	)
)

(defun ct-delete-overlay(file line-no)
  "delete ct overlay in line-no"
  (save-excursion
    (progn
    (find-file file)
    (goto-line line-no)
    (let ((ov (overlays-in (beginning-of-line) (end-of-line))))
      (while (consp ov)
	(when (and (ct-overlay-p (car ov)) (overlay-get (car ov) 'ct-overlay))
	  (delete-overlay (car ov))
	  )
	(setq ov (cdr ov))
	)
      ))))
    
(defun ct-delete-all-ct-overlays(buffer)
    "Delete all flymake overlays in buffer"
	(save-excursion
	    (set-buffer buffer)
		(let ((ov (overlays-in (point-min) (point-max))))
			(while (consp ov)
				(when (and (ct-overlay-p (car ov)) (overlay-get (car ov) 'ct-overlay))
					(delete-overlay (car ov))
					;+(flymake-log 3 "deleted overlay %s" ov)
				)
				(setq ov (cdr ov))
			)
		)
	)
)
;;get err-text in current ct-overlay
(defun ct-line-no-overlay-text(beg end)
  (let* ((ov (overlays-in beg end))
	 (ov-temp)
	 (err-txt nil))
    (while (consp ov)
      (when (ct-overlay-p (setq ov-temp(car ov)))
	(setq err-txt (overlay-get ov-temp 'help-echo))
	)
      (setq ov (cdr ov)))
    err-txt
    ))

(defun ct-region-has-ct-overlays(beg end)
    "t if specified regions has at least one flymake overlay, nil otrherwise"
	(let ((ov                  (overlays-in beg end))
		  (has-ct-overlays  nil))
		(while (consp ov)
			(when (ct-overlay-p (car ov))
			    (setq has-ct-overlays t)
			)
			(setq ov (cdr ov))
		)
	)
)

(defface ct-errline-face
;+   '((((class color)) (:foreground "OrangeRed" :bold t :underline t))
;+   '((((class color)) (:underline "OrangeRed"))
   '((((class color)) (:background "LightPink"))  
     (t (:bold t)))
   "Face used for marking error lines"
    :group 'ct
)
;;file fun line-no text
(defun ct-highlight-line(line-no error-text)
    "highlight line line-no in current buffer, perhaps use text from line-err-info-list to enhance highlighting"
	(goto-line line-no)
	(let* ((line-beg (line-beginning-position))
		   (line-end (line-end-position))
		   (beg      line-beg)
		   (end      line-end)
		   (face     nil))

	    (goto-char line-beg)
	    (while (looking-at "[ \t]")
		    (forward-char)
		)
		
		(setq beg (point))

		(goto-char line-end)
	    (while (and (looking-at "[ \t\r\n]") (> (point) 1))
		    (backward-char)
		)
		
		(setq end (1+ (point)))

		(when (<= end beg)
		    (setq beg line-beg)
			(setq end line-end)
		)
		(when (= end beg)
		    (goto-char end)
			(forward-line)
			(setq end (point))
		)
	
		(setq face 'ct-errline-face)
		(ct-make-overlay beg end error-text face nil line-no)
		)
)


(defun get-buffer-by-mod-name(mod-name)
  (let* ((name nil))
    (progn
      
      ))
)

(defun my-test()
  (interactive)
  (make-error-line "/home/xinming.yao/job/skyFS-controller/"))

(defun make-error-line(base-dir)
  "get ct error and highlight in line no"
  (interactive)
  (save-excursion
  (progn
    (setq erlang-ct-errors nil)
    (get-ct-errors)
    (mapc
     (lambda(error-info)
       (let* ((line-no (nth 2 error-info))
	      (mod-name (nth 0 error-info))
	      (text-error (nth 3 error-info)))
	 (progn
	   ;;(cd "/")
	   (find-file-noselect (concat  base-dir "/test/"  mod-name ".erl"))
	   (set-buffer (concat mod-name ".erl"))
	   (switch-to-buffer (concat mod-name ".erl"))
	   (ct-highlight-line line-no text-error)))) erlang-ct-errors))))




;;;###autoload
(defun inferior-erlang-hack (&optional command)
  "Run an inferior Erlang.
With prefix command, prompt for command to start Erlang with.

This is just like running Erlang in a normal shell, except that
an Emacs buffer is used for input and output.
\\<comint-mode-map>
The command line history can be accessed with  \\[comint-previous-input]  and  \\[comint-next-input].
The history is saved between sessions.

Entry to this mode calls the functions in the variables
`comint-mode-hook' and `erlang-shell-mode-hook' with no arguments.

The following commands imitate the usual Unix interrupt and
editing control characters:
\\{erlang-shell-mode-map}"
  (interactive
   (when current-prefix-arg
     (list (if (fboundp 'read-shell-command)
               ;; `read-shell-command' is a new function in Emacs 23.
	       (read-shell-command "Erlang command: ")
	     (read-string "Erlang command: ")))))
  (require 'comint)
  (let (cmd opts)
    (if command
        (setq cmd "sh"
              opts (list "-c" command))
      (setq cmd inferior-erlang-machine
            opts inferior-erlang-machine-options)
      (cond ((eq inferior-erlang-shell-type 'oldshell)
             (setq opts (cons "-oldshell" opts)))
            ((eq inferior-erlang-shell-type 'newshell)
             (setq opts (append '("-newshell" "-env" "TERM" "vt100") opts)))))

    ;; Using create-file-buffer and list-buffers-directory in this way
    ;; makes uniquify give each buffer a unique name based on the
    ;; directory.
    (let ((fake-file-name (expand-file-name inferior-erlang-buffer-name default-directory)))
      (setq inferior-erlang-buffer (create-file-buffer fake-file-name))
      (apply 'make-comint-in-buffer
             inferior-erlang-process-name
             inferior-erlang-buffer
             cmd
             nil opts)
      (with-current-buffer inferior-erlang-buffer
        (setq list-buffers-directory fake-file-name))))

  (setq inferior-erlang-process
	(get-buffer-process inferior-erlang-buffer))
  (if (> 21 erlang-emacs-major-version)	; funcalls to avoid compiler warnings
      (funcall (symbol-function 'set-process-query-on-exit-flag) 
	       inferior-erlang-process nil)
    (funcall (symbol-function 'process-kill-without-query) inferior-erlang-process))
  (if erlang-inferior-shell-split-window
      (switch-to-buffer-other-window inferior-erlang-buffer)
    (set-buffer  inferior-erlang-buffer)) 
  (if (and (not (eq system-type 'windows-nt))
	   (eq inferior-erlang-shell-type 'newshell))
      (setq comint-process-echoes t))
  (erlang-shell-mode)
 ;; (other-window -1)
  )

(defun inferior-erlang-wait-prompt ()
  "Wait until the inferior Erlang shell prompt appears."
  (if (eq inferior-erlang-prompt-timeout t)
      ()
    (or (inferior-erlang-running-p)
	(error "No inferior Erlang shell is running"))
    (save-excursion
      (set-buffer inferior-erlang-buffer)
      (let ((msg nil))
	(while (save-excursion
		 (goto-char (process-mark inferior-erlang-process))
		 (forward-line 0)
		 (not (looking-at comint-prompt-regexp)))
	  (if msg
	      ()
	    (setq msg t)
	    (message "Waiting for Erlang shell prompt (press C-g to abort)."))
	  (or (accept-process-output inferior-erlang-process
				     inferior-erlang-prompt-timeout)
	      (error "No Erlang shell prompt before timeout")))
	(if msg (message ""))))))


(provide 'extend-ct)

