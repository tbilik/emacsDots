;; enable repos
(require 'package)
(push '("marmalade" . "http://marmalade-repo.org/packages/")
      package-archives )
(push '("melpa" . "http://melpa.milkbox.net/packages/")
      package-archives)
(package-initialize)
;; exwm
;; (require 'exwm)
;; (require 'exwm-config)
;; (exwm-enable)
;; evil mode
(require 'evil)
;; (require 'evil-leader)
(evil-mode 1)
(define-key evil-normal-state-map "A" 'neotree-toggle)
(define-key key-translation-map (kbd "M-h") (kbd "C-w h"))
(define-key key-translation-map (kbd "M-j") (kbd "C-w j"))
(define-key key-translation-map (kbd "M-k") (kbd "C-w k"))
(define-key key-translation-map (kbd "M-l") (kbd "C-w l"))
(define-key evil-normal-state-map "s" 'split-window-below)
(define-key evil-normal-state-map "S" 'split-window-right)
;; (evil-set-initial-state 'compile 'emacs)

;; load path
(add-to-list 'load-path "~/.emacs.d/lisp/")
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
;; file tree
;;(require 'sr-speedbar)

;; variables ....
(setq
 evil-default-cursor t
 inhibit-startup-message t
 initial-scratch-message ";; Emacs scratch buffer: takes quick notes or experiment with elisp." 
 )

;; neotree
(require 'neotree)

;; smart mode line
(require 'powerline)
(setq powerline-default-separator 'slant)
(powerline-default-theme)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes (quote (afternoon)))
 '(custom-safe-themes
   (quote
    ("e8e744a1b0726814ac3ab86ad5ccdf658b9ff1c5a63c4dc23841007874044d4a" "77fac25c0276f636e3914636c45f714c2fd688fe1b1d40259be7ce84b8b5ab1e" "26614652a4b3515b4bbbb9828d71e206cc249b67c9142c06239ed3418eff95e2" "a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" "28ec8ccf6190f6a73812df9bc91df54ce1d6132f18b4c8fcc85d45298569eb53" default)))
)

;; set transparency
;; (set-frame-parameter (selected-frame) 'alpha '(90 90))
;; (add-to-list 'default-frame-alist '(alpha 90 90))

;; change default message of line
(defun display-startup-echo-area-message ()
  (message "Emacs started using recycled electrons."))

;; strip it
(scroll-bar-mode 0)
(tool-bar-mode 0)
(menu-bar-mode 0)

;; line numbers
(global-linum-mode t)

(dired ".")

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Source Code Pro" :foundry "adobe" :slant normal :weight normal :height 120 :width normal)))))
