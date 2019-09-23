;;; screen.el --- terminal initialization for screen and tmux  -*- lexical-binding: t -*-
;; Copyright (C) 1995, 2001-2018 Free Software Foundation, Inc.

;=======================================================================
; Terminal initialization for `putty-256color`.
;=======================================================================

(require 'term/xterm)

(defun terminal-init-putty ()
  "Terminal initialization function for PuTTY."
  (tty-run-terminal-initialization (selected-frame) "xterm"))

(provide 'term/putty)

;; screen.el ends here
