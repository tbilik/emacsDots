;;; exwm-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (or (file-name-directory #$) (car load-path)))

;;;### (autoloads nil "exwm" "exwm.el" (22087 33410 871844 377000))
;;; Generated autoloads from exwm.el

(autoload 'exwm--update-window-type "exwm" "\
Update _NET_WM_WINDOW_TYPE.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-class "exwm" "\
Update WM_CLASS.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-utf8-title "exwm" "\
Update _NET_WM_NAME.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-ctext-title "exwm" "\
Update WM_NAME.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-title "exwm" "\
Update _NET_WM_NAME or WM_NAME.

\(fn ID)" nil nil)

(autoload 'exwm--update-transient-for "exwm" "\
Update WM_TRANSIENT_FOR.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-normal-hints "exwm" "\
Update WM_NORMAL_HINTS.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-hints "exwm" "\
Update WM_HINTS.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-protocols "exwm" "\
Update WM_PROTOCOLS.

\(fn ID &optional FORCE)" nil nil)

(autoload 'exwm--update-state "exwm" "\
Update WM_STATE.

\(fn ID &optional FORCE)" nil nil)

;;;***

;;;### (autoloads nil "exwm-floating" "exwm-floating.el" (22087 33410
;;;;;;  838511 42000))
;;; Generated autoloads from exwm-floating.el

(autoload 'exwm-floating--set-floating "exwm-floating" "\
Make window ID floating.

\(fn ID)" t nil)

(autoload 'exwm-floating--unset-floating "exwm-floating" "\
Make window ID non-floating.

\(fn ID)" t nil)

(autoload 'exwm-floating-toggle-floating "exwm-floating" "\
Toggle the current window between floating and non-floating states.

\(fn)" t nil)

(autoload 'exwm-floating--start-moveresize "exwm-floating" "\
Start move/resize.

\(fn ID &optional TYPE)" nil nil)

(autoload 'exwm-floating--stop-moveresize "exwm-floating" "\
Stop move/resize.

\(fn &rest ARGS)" nil nil)

(autoload 'exwm-floating--do-moveresize "exwm-floating" "\
Perform move/resize.

\(fn DATA SYNTHETIC)" nil nil)

;;;***

;;;### (autoloads nil "exwm-input" "exwm-input.el" (22087 33410 808511
;;;;;;  40000))
;;; Generated autoloads from exwm-input.el

(autoload 'exwm-input--on-KeyPress-line-mode "exwm-input" "\
Parse X KeyPress event to Emacs key event and then feed the command loop.

\(fn KEY-PRESS)" nil nil)

(autoload 'exwm-input-grab-keyboard "exwm-input" "\
Switch to line-mode.

\(fn &optional ID)" t nil)

(autoload 'exwm-input-release-keyboard "exwm-input" "\
Switch to char-mode.

\(fn &optional ID)" t nil)

(autoload 'exwm-input-send-next-key "exwm-input" "\
Send next key to client window.

\(fn TIMES)" t nil)

;;;***

;;;### (autoloads nil "exwm-layout" "exwm-layout.el" (22087 33410
;;;;;;  878511 44000))
;;; Generated autoloads from exwm-layout.el

(autoload 'exwm-layout--show "exwm-layout" "\
Show window ID exactly fit in the Emacs window WINDOW.

\(fn ID &optional WINDOW)" nil nil)

(autoload 'exwm-layout--hide "exwm-layout" "\
Hide window ID.

\(fn ID)" nil nil)

(autoload 'exwm-layout-set-fullscreen "exwm-layout" "\
Make window ID fullscreen.

\(fn &optional ID)" t nil)

;;;***

;;;### (autoloads nil "exwm-manage" "exwm-manage.el" (22087 33410
;;;;;;  841844 375000))
;;; Generated autoloads from exwm-manage.el

(autoload 'exwm-manage--close-window "exwm-manage" "\
Close window ID in a proper way.

\(fn ID &optional BUFFER)" nil nil)

;;;***

;;;### (autoloads nil "exwm-workspace" "exwm-workspace.el" (22087
;;;;;;  33410 865177 710000))
;;; Generated autoloads from exwm-workspace.el

(autoload 'exwm-workspace--update-switch-history "exwm-workspace" "\
Update the history for switching workspace to reflect the latest status.

\(fn)" nil nil)

(autoload 'exwm-workspace-switch "exwm-workspace" "\
Switch to workspace INDEX. Query for INDEX if it's not specified.

The optional FORCE option is for internal use only.

\(fn INDEX &optional FORCE)" t nil)

(autoload 'exwm-workspace-move-window "exwm-workspace" "\
Move window ID to workspace INDEX.

\(fn INDEX &optional ID)" t nil)

;;;***

;;;### (autoloads nil nil ("exwm-config.el" "exwm-core.el" "exwm-pkg.el"
;;;;;;  "exwm-randr.el") (22087 33410 891471 375000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; exwm-autoloads.el ends here
