;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Michelle Monte"
      user-mail-address "michelle.monte@l3harris.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(map! :leader
      (:prefix "w"
       :desc "maximize window" "f" #'my/toggle-maximize-buffer
       :desc "make new frame"  "n" #'make-frame))

(defun my/toggle-maximize-buffer () "Maximize buffer"
  (interactive)
  (if (= 1 (length (window-list)))
      (jump-to-register '_)
    (progn
      (window-configuration-to-register '_)
      (delete-other-windows))))


(map! :leader
      "x" nil
      (:prefix ("x" . "dired")
       :desc "dired here" "d" #'(lambda () (interactive) (dired default-directory))
       :desc "dired" "D" #'dired))

(setq delete-by-moving-to-trash t) ; Move to trash bin instead of permanently deleting it

(defun my/dired-open-externally ()
  "Open marked dired file/folder(s) (or file/folder(s) at point if no marks)
  with external application"
  (interactive)
  (let ((files (dired-get-marked-files)))
    (dired-run-shell-command
     (dired-shell-stuff-it "xdg-open" files t))))

(use-package dired
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :config

  (map! :map dired-mode-map
        :localleader
        "q" #'dired-toggle-read-only)

  ;; (add-to-list 'dired-guess-shell-alist-user '("\\.xlsx\\'" "xdg-open"))
  ;; (add-to-list 'dired-guess-shell-alist-user '("\\.xlsb\\'" "xdg-open"))

 (evil-define-key* '(normal) dired-mode-map
   (kbd "M-RET") #'my/dired-open-externally)

  (evil-collection-define-key 'normal 'dired-mode-map
    ;; "h" 'dired-single-up-directory
    ;; "l" 'dired-single-buffer)
    "h" 'dired-up-directory
    "l" 'dired-find-file
    )
  (setq dired-recursive-deletes "top"))


;; Completion stuff
(use-package! lsp-mode
  :diminish (lsp-mode . "lsp")
  :bind (:map lsp-mode-map
    ("C-c C-d" . lsp-describe-thing-at-point))
  :config
  ;; make sure we have lsp-imenu everywhere we have LSP
  (setq lsp-completion-provider :capf)
  (setq lsp-idle-delay 0.25)
  (setq gc-cons-threshold 100000000)
  (require 'lsp-ui-imenu)
  (add-hook 'lsp-after-open-hook 'lsp-enable-imenu)
  ;; get lsp-python-enable defined
  ;; NB: use either projectile-project-root or ffip-get-project-root-directory
  ;;     or any other function that can be used to find the root directory of a project
  ;; (lsp-define-stdio-client lsp-python "python"
  ;;                          #'projectile-project-root
  ;;                          '("pyright"))
        (lsp-register-client
        (make-lsp-client :new-connection (lsp-stdio-connection "pyright")
                        :major-modes '(python-mode)
                        :server-id 'pyright))
  ;; make sure this is activated when python-mode is activated
  ;; lsp-python-enable is created by macro above
  ;; (add-hook 'python-mode-hook
  ;;           (lambda ()
  ;;             (lsp-python-enable)))

  ;; lsp extras
  (use-package lsp-ui
    :ensure t
    :config
    (setq lsp-ui-sideline-ignore-duplicate t)
    (add-hook 'lsp-mode-hook 'lsp-ui-mode))

(add-hook 'c-mode-hook (lambda () (lsp-lens-mode -1)))
(add-hook 'c-mode-hook (lambda () (ccls-code-lens-mode -1)))
(setq lsp-lens-enable nil)
(setq lsp-enable-symbol-highlighting nil)

  ;;(use-package company-lsp
  ;;  :config
  ;;  (push 'company-lsp company-backends))

  :init
  (setq lsp-auto-guess-root t       ; Detect project root
   lsp-log-io nil
   lsp-enable-indentation t
   lsp-enable-imenu t
   lsp-keymap-prefix "C-l"
   lsp-file-watch-threshold 2000
   lsp-prefer-flymake nil)      ; Use lsp-ui and flycheck

  (defun lsp-on-save-operation ()
    (when (or (boundp 'lsp-mode)
         (bound-p 'lsp-deferred))
      (lsp-organize-imports)
      (lsp-format-buffer)))
  )
(use-package! lsp-ui
  :after (lsp-mode)
  :commands lsp-ui-doc-hide
  :bind (:map lsp-ui-mode-map
         ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
         ([remap xref-find-references] . lsp-ui-peek-find-references)
         ("C-c u" . lsp-ui-imenu))
  :init (setq lsp-ui-doc-enable t
         lsp-ui-doc-use-webkit nil
         lsp-ui-doc-header nil
         lsp-ui-doc-delay 0.2
         lsp-ui-doc-include-signature t
         lsp-ui-doc-alignment 'at-point
         lsp-ui-doc-use-childframe nil
         lsp-ui-doc-border (face-foreground 'default)
         lsp-ui-peek-enable t
         lsp-ui-peek-show-directory t
         lsp-ui-sideline-update-mode 'line
         lsp-ui-sideline-enable t
         lsp-ui-sideline-show-code-actions t
         lsp-ui-sideline-show-hover nil
         lsp-ui-sideline-ignore-duplicate t)
  :config
  (add-to-list 'lsp-ui-doc-frame-parameters '(right-fringe . 8))

  ;; `C-g'to close doc
  (advice-add #'keyboard-quit :before #'lsp-ui-doc-hide)

  ;; Reset `lsp-ui-doc-background' after loading theme
  (add-hook 'after-load-theme-hook
       (lambda ()
         (setq lsp-ui-doc-border (face-foreground 'default))
         (set-face-background 'lsp-ui-doc-background
                              (face-background 'tooltip))))

  ;; WORKAROUND Hide mode-line of the lsp-ui-imenu buffer
  ;; @see https://github.com/emacs-lsp/lsp-ui/issues/243
  (defadvice lsp-ui-imenu (after hide-lsp-ui-imenu-mode-line activate)
    (setq mode-line-format nil)))

;; taken from emacs-lsp.github.io "configuring emacs as a c/c++ ide"
;; (require 'package)
;; (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
;; (package-initialize)
;; (setq package-selected-packages '(lsp-mode yasnippet lsp-treemacs helm-lsp
;;     projectile hydra flycheck company avy which-key helm-xref dap-mode))
;; (when (cl-find-if-not #'package-installed-p package-selected-packages)
;;   (package-refresh-contents)
;;   (mapc #'package-install package-selected-packages))
;; sample `helm' configuration use https://github.com/emacs-helm/helm/ for details
;; (helm-mode)
;; (require 'helm-xref)
;; (define-key global-map [remap find-file] #'helm-find-files)
;; (define-key global-map [remap execute-extended-command] #'helm-M-x)
;; (define-key global-map [remap switch-to-buffer] #'hel
  ;; m-mini)
(which-key-mode)
(add-hook 'c-mode-hook 'lsp)
(add-hook 'c++-mode-hook 'lsp)
(setq gc-cons-threshold (* 100 1024 1024)
      read-process-output-max (* 1024 1024)
      treemacs-space-between-root-nodes nil
      company-idle-delay 0.0
      company-minimum-prefix-length 1
      lsp-idle-delay 0.1)  ;; clangd is fast
(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)
  (yas-global-mode))


;; terminal stuff
(use-package! vterm
  :commands vterm vterm-mode
  ;; :hook (vterm-mode . doom-mark-buffer-as-real-h)
  :init
  ;; Add current path to Vterm modeline
  (require 'doom-modeline-core)
  (require 'doom-modeline-segments)
  (doom-modeline-def-modeline 'my-vterm-mode-line
    '(bar workspace-name window-number modals matches buffer-default-directory buffer-info remote-host buffer-position word-count parrot selection-info)
    '(objed-state misc-info persp-name battery grip irc mu4e gnus github debug lsp minor-modes input-method indent-info buffer-encoding major-mode process vcs checker))
  (add-hook! 'vterm-mode-hook (doom-modeline-set-modeline 'my-vterm-mode-line))

  (evil-define-key '(normal insert) vterm-mode-map
    (kbd "M-k") 'vterm-send-up
    (kbd "M-j") 'vterm-send-down)

  :config
  ;; Once vterm is dead, the vterm buffer is useless. Why keep it around? We can
  ;; spawn another if want one.
  (setq vterm-kill-buffer-on-exit t)
  (setq vterm-max-scrollback 5000)
  (setq confirm-kill-processes nil)
  (setq-hook! 'vterm-mode-hook
    ;; Don't prompt about dying processes when killing vterm
    confirm-kill-processes nil
    ;; Prevent premature horizontal scrolling
    hscroll-margin 0)
  (map! :localleader
        :map (vterm-mode-map vterm-copy-mode-map)
          "c" #'vterm-copy-mode)
  ;; Restore the point's location when leaving and re-entering insert mode.
  ;; (add-hook! 'vterm-mode-hook
  ;;   (defun +vterm-init-remember-point-h ()
  ;;     (add-hook 'evil-insert-state-exit-hook #'+vterm-remember-insert-point-h nil t)
  ;;     (add-hook 'evil-insert-state-entry-hook #'+vterm-goto-insert-point-h nil t)))
)

(defun show-current-working-dir-in-mode-line ()
  "Shows current working directory in the modeline."
  (interactive)
  (setq mode-line-format '("" default-directory))
  )

(defun open-named-terminal (termName2)
  (vterm)
  (rename-buffer termName2 t)
  (evil-normal-state))

(defun find-named-terminal (termName)
  (catch 'exit-find-named-terminal
    (if
        (string-match-p termName (buffer-name (current-buffer)))
        (bury-buffer (buffer-name (current-buffer))))

    (dolist (b (buffer-list))
      (if (string-match-p termName (buffer-name b))
          (progn
           (switch-to-buffer b)
           (throw 'exit-find-named-terminal nil))))

    (open-named-terminal termName))
  )

(defun find-std-terminal ()
  (interactive)
  (find-named-terminal "std-term"))

(defun open-std-terminal ()
  (interactive)
  (open-named-terminal "std-term"))

(defun find-maint-terminal ()
  (interactive)
  (find-named-terminal "maint-term"))

(defun open-maint-terminal ()
  (interactive)
  (open-named-terminal "maint-term"))

(map! :leader
      (:prefix "w"
        :desc "Open maint term"  "M"  #'open-maint-terminal
        :desc "Go to maint term" "m"  #'find-maint-terminal
        :desc "Open std term"    "T"  #'open-std-terminal
        :desc "Go to std term"   "t"  #'find-std-terminal))

;; Add directory & descendant directories to load path
;; (let ((default-directory "~/dark_helmet/privatePlugins"))
;; (normal-top-level-add-subdirs-to-load-path))

;; (use-package xwwp-full
;;   :load-path "~/.emacs.d/xwwp"
;;   :custom
;;   (xwwp-follow-link-completion-system 'helm)
;;   :bind (:map xwidget-webkit-mode-map
;;               ("v" . xwwp-follow-link)
;;               ("t" . xwwp-ace-toggle)))

;; (map! :leader
;;       "a" nil)

(defun what-face (pos)
  (interactive "d")
  (let ((face (or (get-char-property (pos) 'read-face-name)
                  (get-char-property (pos) 'face))))
    (if face (message "Face: %s" face) (message "No face at %d" pos))))

;; (add-hook! 'org-capture-mode-hook)
;; ;; ORG Capture
;;   (add-to-list 'org-capture-templates
;;         ;; '(("t" "Todo" entry (file+headline (concat org-directory "inbox.org") "Tasks")
;;           ;; "* TODO %?\n  %U\n  %i\n  %a")
;;         '("c" "Code Snippet" entry
;;          ;; (file (concat org-directory "/snippets.org"))
;;          (file "~/org/snippets.org")
;;          ;; Prompt for tag and language
;;          "* %A \n#+BEGIN_SRC c\n%i#+END_SRC"))
;;          ("m" "Media" entry
;;           (file+datetree (concat org-directory "media.org"))
;;           "* %?\nURL: \nEntered on %U\n")))

(defun org-hide-src-block-delimiters()
  (interactive)
  (save-excursion (goto-char (point-max))
      (while (re-search-backward "#\\+BEGIN_SRC\\|#\\+END_SRC" nil t)
         (let ((ov (make-overlay (line-beginning-position)
             (1+ (line-end-position)))))
         (overlay-put ov 'invisible t)))))

(load "~/.doom.d/clangd_lspCfg.el")
;; language parser
(use-package! tree-sitter
  :config
  (require 'tree-sitter-langs)
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))


;; pdf-tool stuff
(setq pdf-view-resize-factor 1.1)

(defun my/magit-status ()
  "Use ivy to specify directory from which to open a magit status buffer.
Default starting place is the home directory."
  (interactive)
  (let ((default-directory "~/"))
    (ivy-read "git status: " #'read-file-name-internal
              :matcher #'counsel--find-file-matcher
              :action #'(lambda (x)
                          (magit-status x))
              :preselect (counsel--preselect-file)
              :require-match 'confirm-after-completion
              :history 'file-name-history
              :keymap counsel-find-file-map
              :caller 'my/magit-status)))

(use-package! magit
  :config
  (map! :leader
        (:prefix "g"
         :desc "blame" "b" #'magit-blame
         ;; :desc "status dwim" "g" #'magit-status
         :desc "status" "G" #'my/magit-status
         :desc "buffer-lock" "T" #'magit-toggle-buffer-lock

         ;; Git gutter
         :desc "next-hunk" "j" #'git-gutter:next-hunk
         :desc "prev-hunk" "k" #'git-gutter:previous-hunk
         :desc "popup-diff" "d" #'git-gutter:popup-diff
         :desc "file-statistics" "S" #'git-gutter:statistic

         "s" nil
         (:prefix ("s" . "status")
          :desc "find"       "s" #'my/magit-status
         )

         ;; Log
         :desc "log" "l" #'magit-log
         "L" nil ;; unmap default L mapping
         (:prefix ("L" . "log")
          :desc "file" "f" #'magit-log-buffer-file
          :desc "head" "h" #'magit-log-head
          :desc "log" "i" #'magit-log
          :desc "refresh" "r" #'magit-log-refresh-buffer))))
