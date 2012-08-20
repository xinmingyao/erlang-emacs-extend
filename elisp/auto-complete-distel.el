;; auto-complete-distel.el
;;
;; Most of the code here is ripped from distel and erlang-mode.
;;
;; It assumes you have a node up and running and will kind of
;; intellisense-ishy complete module names and function names.
;;
;; To use this add something like this to your auto-complete-mode
;; configuration:
;;
;; (defun ac-distel-setup ()
;;   (setq ac-sources '(ac-source-distel)))
;;
;; (add-hook 'erlang-mode-hook 'ac-distel-setup)
;; (add-hook 'erlang-shell-mode-hook 'ac-distel-setup)
;;
;; modify by yaoxinming@gmail.com
;; add macro and record autocomplete
;; TODO:
;; Add documentation support

(require 'auto-complete)

(defvar ac-source-distel
  '((candidates . ac-distel-candidates)
    (requires . 0)
    (cache)))

(defvar ac-distel-candidates-cache nil
  "Horrible global variable that caches the selection to be returned.")

(defun ac-distel-candidates ()
  (ac-distel-com)
  ac-distel-candidates-cache)




(defun do_fun(node beg end)
  (let* ((str (buffer-substring-no-properties beg end))
             (buf (current-buffer))
             (continuing (equal last-command (cons 'erl-complete str))))
        (setq this-command (cons 'erl-complete str))
	(message "%s" str)
        (if (string-match "^\\(.*\\):\\(.*\\)$" str)
            ;; completing function in module:function
            (let ((mod (intern (match-string 1 str)))
                  (pref (match-string 2 str))
                  (beg (+ beg (match-beginning 2))))
              (erl-spawn
               (erl-send-rpc node 'distel 'functions (list mod pref))
               (&ac-distel-receive-completions "function" beg end pref buf
                                               continuing)))
          ;; completing just a module
          (erl-spawn
           (erl-send-rpc node 'distel 'modules (list str))
           (&ac-distel-receive-completions "module" beg end str buf continuing)))))


(defun ac-distel-com ()
  "Complete the module or remote function name at point."
  (interactive)
  (let ((cmd )
	(str)
	(beg )
	(end (point))
	(node erl-nodename-cache)
	)
    (save-excursion
      (progn 
	(skip-chars-backward "a-zA-z0-9:?#.")
	(setq beg (point))
	(setq str (buffer-substring-no-properties beg end))
    
	(setq cmd (cond ((string-match "^\\(.*\\):\\(.*\\)$" str)
			(let* ((mod (intern (match-string 1 str)))
			       (pref (match-string 2 str)))
			  
			  (complete-fun mod pref)))
		       ((string-match "^\\?\\(.*\\)$" str)
			(let* (
			       (name (match-string 1 str)))
			  (message name)
			  (complete-macros  name)))
		       ((string-match "^[a-zA-Z0-9-_]*#\\([a-zA-Z0-9-_]*\\)$" str)
			(let* (
			       (name (match-string 1 str)))
			   (message name)
			  (complete-records  name)))
		       ((string-match "^[a-zA-Z0-9-_]*#\\([a-zA-Z0-9-_]*\\)\\..*$" str)
			(let* (
			       (name (match-string 1 str)))
			  (message name)
			  (complete-records-name  name)))
		       ((string-match "^\\([a-zA-Z0-9-_]*\\).*$" str)
			 (let* (
			       (name (match-string 1 str)))
			  (complete-module  name)))
		       (t (message "t"))))
	))
     ;; (funcall cmd)
    ))



(defun save-module()
  (let ((node erl-nodename-cache)
	(module-name  (concat (file-name-sans-extension (file-name-nondirectory buffer-file-name)) ".erl"))
	(base-dir (erlang-application-base-dir buffer-file-name))
	)
    (erl-spawn
      (erl-send-rpc node 'extend_module_info 'create_mod (list module-name base-dir))
      (erl-receive ()
	  ((other
	    (message "ok")))))))

;;(add-hook 'after-save-hook 'save-module)

(defun complete-fun (mod pref)
  (let ((node erl-nodename-cache)
	(module-name)
	(buf (current-buffer))
	)
    (erl-spawn
      (erl-send-rpc node 'distel 'functions (list mod pref))
      (&ac-distel-receive-completions "function" "beg" "end" "pref" buf
				    "continuing"))))

(defun complete-macros(name)
  (let ((node erl-nodename-cache)
	(module-name  (concat (buffer-name) ""))
	(base-dir (erlang-application-base-dir buffer-file-name))
	(buf (current-buffer))
	)
    (message name)
    (erl-spawn
    (erl-send-rpc node 'extend_module_info 'get_macro (list module-name name base-dir))
    (&ac-distel-receive-completions "function" "beg" "end" "pref" buf
				    "continuing"))))


(defun complete-records(name)
  (let ((node erl-nodename-cache)
	(module-name  (concat (buffer-name) ""))
	(base-dir (erlang-application-base-dir buffer-file-name))
	(buf (current-buffer))
	)
    (message name)
    (erl-spawn
    (erl-send-rpc node 'extend_module_info 'get_records (list module-name name base-dir))
    (&ac-distel-receive-completions "function" "beg" "end" "pref" buf
				    "continuing"))))

(defun complete-records-name(name)
  (let ((node erl-nodename-cache)
	(module-name  (concat (buffer-name) ""))
	(base-dir (erlang-application-base-dir buffer-file-name))
	(buf (current-buffer))
	)
    (erl-spawn
    (erl-send-rpc node 'extend_module_info 'get_record_name (list module-name name base-dir))
    (&ac-distel-receive-completions "function" "beg" "end" "pref" buf
				    "continuing"))))

(defun complete-module(name)
  (let ((node erl-nodename-cache)
	(module-name  (concat (buffer-name) ""))
	(buf (current-buffer))
	)

    (erl-spawn
    (erl-send-rpc node 'distel 'modules (list  name ))
    (&ac-distel-receive-completions "function" "beg" "end" "pref" buf
				    "continuing"))))


(defun &ac-distel-receive-completions (what beg end prefix buf continuing)
  (let ((state (erl-async-state buf)))
    (erl-receive (what state beg end prefix buf continuing)
        ((['rex ['ok completions]]
          (setq ac-distel-candidates-cache completions))
         (['rex ['error reason]]
          (message "Error: %s" reason))
         (other
          (message "Unexpected reply: %S" other))))))


(provide 'auto-complete-distel)
