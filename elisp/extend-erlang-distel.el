(require 'erlang)
(require 'distel)
(require 'flymake)
(require 'extend-ct)
(require 'extend-flymake)
;;open erlang and not split window
(setq erlang-inferior-shell-split-window nil)


(defun uuid-create ()
  "Return a newly generated UUID. This uses a simple hashing of variable data."
  (let ((s (md5 (format "%s%s%s%s%s%s%s%s%s%s"
                        (user-uid)
                        (emacs-pid)
                        (system-name)
                        (user-full-name)
                        user-mail-address
                        (current-time)
                        (emacs-uptime)
                        (garbage-collect)
                        (random)
                        (recent-keys)))))
    (format "%s%s3%s%s%s"
            (substring s 0 8)
            (substring s 8 12)
            (substring s 13 16)
            (substring s 16 20)
            (substring s 20 32))))

(defun restart-erlang-shell()
  "kill the erlang buffer in buffer list and restart a erlang-shell "
  (interactive)
  (let* ((temp nil))
    (progn
      (and (inferior-erlang-running-p)
	  (kill-buffer inferior-erlang-buffer-name))
      ;; (setq buffer-modified-p temp)
      (save-excursion
	(inferior-erlang-hack)
	
      ;;(switch-to-buffer temp)
      )
      )
    ;; (other-window -1)
    ))


(defun compile-erlang-code()
  (interactive)
  (let* ((dir (inferior-erlang-compile-outdir))
;;; (file (file-name-nondirectory (buffer-file-name)))
         (noext (substring (buffer-file-name) 0 -4))
         (opts (append (list (cons 'outdir dir))
                       (if current-prefix-arg
                           (list 'debug_info 'export_all))
                       erlang-compile-extra-opts))
         end)
    (save-excursion
      (set-buffer inferior-erlang-buffer)
      (compilation-forget-errors))
    (setq end (inferior-erlang-send-command
               (inferior-erlang-compute-compile-command noext (append opts (list (cons 'i (erlang-application-include))) (list 'debug_info) (list 'export_all)))
               nil))))

;;send ct:run to erlang shell
(defun run-erlang-ct()			;
  (interactive)
  (let* ((module-name (erlang-ct-module-name buffer-file-name))
	 (cmd (concat "ct:run(\"" (erlang-application-test) "\",\"" module-name "\")."))
	 )
;;    (save-excursion
      (progn
	(set-buffer inferior-erlang-buffer)
	(inferior-erlang-wait-prompt)
	(inferior-erlang-send-command "application:set_env(common_test,auto_compile,false).")
	(inferior-erlang-send-command cmd)
;;      )
)))


;;send ct:run to erlang shell
(defun run-erlang-main()
  (interactive)
  (let* ((module-name (erlang-ct-module-name buffer-file-name))
	 (cmd (concat  module-name ":" "main([])."))
	 )
;;    (save-excursion
      (progn
      (set-buffer inferior-erlang-buffer)
      (inferior-erlang-wait-prompt)
      (inferior-erlang-send-command cmd)
      (enlarge-window-horizontally -50)
;;      )
)))
   
;;  /tmp/test.erl ->test_SUITE
;;  /tmp/test_SUITE ->test_SUITE  
(defun erlang-ct-module-name(file-path)
  (interactive)
  (let* ((module-name))
  (setq module-name (file-name-sans-extension (file-name-nondirectory file-path)))
  (if (string-match-p "^\\(.+\\)_SUITE$" module-name)
      (setq module-name module-name)
      (concat  module-name "_SUITE")) 
  ))

;; Some Erlang customizations
(defun erlang-application-base-dir ()
  (interactive)
  (let ((src-path (file-name-directory (buffer-file-name))))
    (file-name-directory (directory-file-name src-path))))

(defun  erlang-application-ebin()
	(concat (erlang-application-base-dir) "ebin"))
(defun  erlang-application-test()
	(concat (erlang-application-base-dir) "test"))
(defun  erlang-application-deps()
	(let* ((deps (concat (erlang-application-base-dir) "deps"))
	     (temp nil))
	     (if (file-directory-p deps)
	     (progn	     
	     (setq deps (directory-files deps))
	     (setq temp (mapcar (lambda (dir) 
				  (list "-pa" (concat (erlang-application-base-dir) "deps/" dir "/ebin"))) deps))
	     (apply #'append temp) )
             (setq temp nil))	
	))
(defun  erlang-application-include()
	(concat (erlang-application-base-dir) "include"))

(setq erlang-distel-extend-uuid (uuid-create))
(setq erlang-distel-default-nodename (concat erlang-distel-extend-uuid ""))

(defun start-erl-opts()
  (let ((home (concat "/home/" (getenv "USER"))))
    (list "-pa" (erlang-application-ebin) 
	  "-pa" (concat home "/elisp/distel/ebin/")
	  "-pa" (concat home "/elisp/erlang-emacs-extend/ebin/")
	  "-pa" (erlang-application-test)  
	  "-i" (erlang-application-include) "-sname" erlang-distel-default-nodename)))
(add-hook 'erlang-mode-hook
	  (lambda ()
	    ;; compaple to distel,distel add erlang-mode in some no filebuffer
	    (and buffer-file-name (progn
				    (setq inferior-erlang-machine-options (append (erlang-application-deps) (start-erl-opts)))
;;				    (setq erl-nodename-cache (intern (concat erlang-distel-default-nodename "@" (erl-determine-hostname))))	
				    (setq erl-nodename-cache (intern (concat erlang-distel-default-nodename "@localhost")))	
				   ;; (push 'ac-source-distel ac-sources)
				   ;; (message (erlang-application-ebin))
				    ;;(append ac-sources 'ac-source-distel)
				    ;; (setq ac-sources '(ac-source-distel))
				    ;; (ac-set-trigger-key "TAB")
				    (setq ac-omni-completion-sources (list (cons ":" '(ac-source-distel)))) 
				    (setq erlang-ac 1)
				    (ac-sources-change)
				    ;; (setq-default ac-sources '(ac-source-distel))
				    (flymake-find-file-hook)	
				    (setq distel-ac nil)
				    ;;(local-set-key (kbd "C-c :") 'ac-complete-semantic)
				    (setq old-ac-sources ac-sources)
				    ;;	    (add-hook 'pre-command-hook 'ac-sources-change)
				    (or (inferior-erlang-running-p)
					(save-excursion
					  (progn
					   
					    (erlang-shell)
					    (inferior-erlang-wait-prompt)
					    (kill-edb-monitor)
					  ;;  (erl-ping  erlang-distel-default-nodename)
					  ;;  (edb-monitor (concat erlang-distel-default-nodename "@" (erl-determine-hostname)))
					  ;;  (edb-monitor)
					  ;;  (kill-buffer edb-monitor-buffer)
					    ;;(erl-reload-modules))
					    )))))))
;;(delete-other-windows)

(add-hook 'erlang-shell-mode-hook 
	  (lambda()

	    (push 'ac-source-distel ac-sources)))
;;	    (edb-monitor (concat erlang-distel-default-nodename "@" (erl-determine-hostname)))
;;	    (kill-buffer edb-monitor-buffer)))
(defadvice save-buffers-kill-emacs(around no-query-kill-emacs activate)
"Prevent annoying \"Active processes exist \" query when you exit Emacs."
(flet ((process-list())) ad-do-it))


;;use ac-source-distel when type :

;;(global-set-key (kbd ":") 'ac-sources-change1)
(defun ac-sources-change1()
  (interactive)
  (message "test")
  (setq ac-sources '(ac-source-distel))
  (setq ac-auto-start 1)
  (setq distel-ac t))

(defun ac-sources-change()
(interactive)
;;(if (not distel-ac)
;    (let* ((char (save-excursion 
;		   (progn
;		     (and (backward-char)
;		     (get-byte))))))
;;      (message (char-to-string char))
;      (if (= char ?:)
;	  (progn
;	    (message "333")
;	    (setq ac-sources '(ac-source-distel))
;	    (setq ac-auto-start 1)
;	    (setq distel-ac t))))
;;(message "t")
(and (> (point) 0) distel-ac
     (let* ((point (point))
	    (line-str (buffer-substring-no-properties (line-beginning-position) (point)))
	    )
       (save-excursion
	 (progn
	   (string-match ".*:\\([a-zA-Z0-9\\-_]+\\).*" line-str)
	   (if (> point (+ (line-beginning-position) (match-end 1)))
	       (progn
		 (setq distel-ac nil)
		 (setq ac-sources old-ac-sources)
		 (setq ac-auto-start 2))))))))

(setq erlang-ac nil)
(defun ac-sources-change()
  "change ac-source"
  (interactive)
  (progn
    (if (not erlang-ac)
	(progn
	  (message "nil")
	  (setq ac-sources '(
		  ac-source-yasnippet  
		  ac-source-semantic  
                  ac-source-imenu  
                  ac-source-abbrev  
                  ac-source-words-in-buffer  
                  ;;ac-source-files-in-current-dir  
                  ac-source-filename)
                  ) 
	  (setq erlang-ac 1))
      (progn
	(message "1")
	(setq ac-sources '(ac-source-distel ac-source-yasnippet))
	(setq erlang-ac nil)))))
(defun erlang-save-and-compile()
  "save buffer and compile the erlang code"
  (interactive)
  (progn
    (save-buffer)
    (save-module)
    (compile-erlang-code)))

(global-set-key [f6] 'ac-sources-change)
(defconst erlang-distel-extend-keys
  '(("\C-x\C-s" erlang-save-and-compile)
    ("\C-ct" restart-erlang-and-run-ct)
    ("\C-ce" restart-erlang-and-run-ct-one-fun)
    ("\C-cd" erlang-run-debug)
    ("\C-cm" restart-erlang-shell-and-run-main))
  "Keys to bind in erlang-distel-extend")


(defun erlang-run-debug()
  (interactive)
  (let* ((temp (buffer-name))
	 (test-mod  (concat (erlang-ct-module-name buffer-file-name) ".erl"))
	 (base-dir (erlang-application-base-dir)))    
    (save-excursion
      (progn 
	(setq erlang-inferior-shell-split-window t)
	;;(restart-erlang-shell)
	(run-erlang-main)
	(set-buffer inferior-erlang-buffer-name)
	;;(inferior-erlang-wait-prompt)
	;;(make-error-line base-dir)
	))
  ))

(defun restart-erlang-shell-and-run-main()
  (interactive)
  (let* ((temp (buffer-name))
	 (test-mod  (concat (erlang-ct-module-name buffer-file-name) ".erl"))
	 (base-dir (erlang-application-base-dir)))    
    (save-excursion
      (progn 
	(setq erlang-inferior-shell-split-window t)
	(restart-erlang-shell)
	(run-erlang-main)
	(set-buffer inferior-erlang-buffer-name)
	(inferior-erlang-wait-prompt)
	(setq is_kill_edb nil)
	(kill-edb-monitor )
	;;(make-error-line base-dir)
	))
  ))
;;restart a elrang shell,and run common test by buffer name and
;; if error make red color on error line num



(setq cmd1 "")
(defun run-ct-one-fun()
  (interactive)
  (let* (
	(test-dir (erlang-application-test))
	(module (concat  (erlang-application-test) "/"  (erlang-ct-module-name buffer-file-name)))
	(line (line-number-at-pos))
	)
    (erl-get-fun test-dir module line)
    ))
(defun erl-get-fun (test-dir module line)
  "Goto the caller that is at point."
  (interactive)
  (let (
	(mod-name (erlang-ct-module-name buffer-file-name))
	(module-name2  (concat (buffer-name) ""))
	(node (or erl-nodename-cache (erl-target-node))))
    
    (erl-spawn
      (erl-send-rpc node 'extend_module_tool 'get_fun (list (intern module) line))
      (erl-receive (test-dir module line mod-name cmd1 module-name2)
	  ((['rex ['ok fun_name]]
	    (message "fun :%s" fun_name)
	    (progn
	      (erl-run-ct-testcase test-dir module-name2 fun_name)
	     ;; (inferior-erlang-send-command "application:set_env(common_test,auto_compile,false).")
	     ;; (inferior-erlang-send-command  (concat "ct:run(\"" test-dir "\",\"" mod-name "\"," (concat "\[" fun_name "\]") ")."))
;;	      (setq cmd1 (concat "ct:run(\"" test-dir "\",\"" mod-name "\"," (concat "\[" fun_name "\]") ")."))
	      )
	    )
	   (['rex ['error reason]]
	    (message "Error: %s" reason)))))))

(defun erl-run-ct-testcase(test-dir mod-name testcase)
  (interactive)
  (let (
	(node (or erl-nodename-cache (erl-target-node))))

    (erl-spawn
      (erl-send-rpc node 'extend_ct_tool 'run_ct (list test-dir mod-name testcase))
      (erl-receive ()
	  ((['rex ['failed file line_no msg]]

	    (progn
	      (find-file file)
	      (goto-line line_no)
	      (ct-highlight-line line_no msg)
	      ;;(inferior-erlang-send-command "a.")
	      (message "msg :%s" msg)	      
	      )
	    )
	   (other
	    (message "ct run: %s" other)))))))
    


(defun restart-erlang-and-run-ct-one-fun()
  "restart erlang-shell and common test"
  (interactive)
  (let* ((temp (buffer-name))
	 (cmd "")
	 (test-mod  (concat (erlang-ct-module-name buffer-file-name) ".erl"))
	 (base-dir (erlang-application-base-dir)))    
    (save-excursion
      (progn 
	(and (bufferp test-mod)
	     (ct-delete-own-overlays test-mod))
	(setq erlang-inferior-shell-split-window t)
	(run-ct-one-fun)
;;	(inferior-erlang-wait-prompt)
	;;(restart-erlang-shell)
;;	(inferior-erlang-wait-prompt)
;;	(message "hello %s" cmd1)
;;	(inferior-erlang-send-command  cmd1)
;;	(set-buffer inferior-erlang-buffer-name)
;;	(inferior-erlang-wait-prompt)
;;	(make-error-line base-dir)
	))
    ;;    (other-window -1)
    ;;  (switch-to-buffer temp)
    ;;  (inferior-erlang-display-buffer nil)
    
  ))

(defun restart-erlang-and-run-ct()
  "restart erlang-shell and common test"
  (interactive)
  (let* ((temp (buffer-name))
	 (test-mod  (concat (erlang-ct-module-name buffer-file-name) ".erl"))
	 (base-dir (erlang-application-base-dir)))    
    (save-excursion
      (progn 
	(and (bufferp test-mod)
	     (ct-delete-own-overlays test-mod))
;;	(setq erlang-inferior-shell-split-window t)
	(restart-erlang-shell)
	(run-erlang-ct)
	(set-buffer inferior-erlang-buffer-name)
	(inferior-erlang-wait-prompt)
	(make-error-line base-dir)
	))
    ;;    (other-window -1)
    ;;  (switch-to-buffer temp)
    ;;  (inferior-erlang-display-buffer nil)
    
  ))

(defun erlang-distel-extend-bind-keys()
  "bind keys for extend in erlang-distel-extend-keys map"
  (interactive)
  (dolist (spec erlang-distel-extend-keys)
    (define-key erlang-extended-mode-map (car spec) (cadr spec))))
(erlang-distel-extend-bind-keys)

(setq is_kill_edb nil)
(defun kill-edb-monitor ()
  (interactive)
;;  (edb-monitor-cleanup)
  (if (not is_kill_edb)
      (let* ((node (erl-target-node)))
	(message "11")
	(when (edb-ensure-monitoring node)
	  (unless (get-buffer-window edb-monitor-buffer)
	    ;; Update the restorable window configuration
	    (with-current-buffer edb-monitor-buffer
	      (setq erl-old-window-configuration
		    (current-window-configuration))))
	  (kill-buffer edb-monitor-buffer)
	  (edb-ensure-monitoring node)
	  (setq is_kill_edb t)
	  ))))
(provide 'extend-erlang-distel)
