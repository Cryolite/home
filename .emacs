;=======================================================================
; I18n
;=======================================================================

; https://www.gnu.org/software/emacs/manual/html_node/emacs/Language-Environments.html
(set-language-environment "Japanese")

; https://www.gnu.org/software/emacs/manual/html_node/emacs/Recognize-Coding.html
(prefer-coding-system 'utf-8)

; https://www.gnu.org/software/emacs/manual/html_node/emacs/Text-Coding.html
(setq-default buffer-file-coding-system 'utf-8)

; https://www.gnu.org/software/emacs/manual/html_node/emacs/File-Name-Coding.html
; This is not actually necessary if `prefer-coding-system` is set.
(set-file-name-coding-system 'utf-8)

; https://www.gnu.org/software/emacs/manual/html_node/emacs/Terminal-Coding.html
; This is not actually necessary if `prefer-coding-system` is set.
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)


;=======================================================================
; Fonts
;=======================================================================
;(cond (window-system
;    (set-default-font "-*-fixed-medium-r-normal--14-*-*-*-*-*-*-*")
;       (progn
;         (set-face-font 'default
;                        "-shinonome-gothic-medium-r-normal--14-*-*-*-*-*-*-*")
;         (set-face-font 'bold
;                        "-shinonome-gothic-bold-r-normal--14-*-*-*-*-*-*-*")
;         (set-face-font 'italic
;                        "-shinonome-gothic-medium-i-normal--14-*-*-*-*-*-*-*")
;         (set-face-font 'bold-italic
;                        "-shinonome-gothic-bold-i-normal--14-*-*-*-*-*-*-*")
;       )))


;=======================================================================
; Frame size, position, color, etc.
;=======================================================================
;(setq initial-frame-alist
;    (append (list
;           '(foreground-color . "white")
;           '(background-color . "#333366")
;           '(border-color . "black")
;           '(mouse-color . "white")
;           '(cursor-color . "white")
;           '(width . 90)
;           '(height . 49)
;           '(top . 0)
;           '(left . 340)
;           )
;        initial-frame-alist))
;(setq default-frame-alist initial-frame-alist)


;=======================================================================
; Color
;=======================================================================
(set-background-color "black")
(set-foreground-color "white")
(set-cursor-color "white")


;=======================================================================
; Misc
;=======================================================================
(global-font-lock-mode t)
(line-number-mode t)
(column-number-mode t)
(auto-compression-mode t)
;(global-set-key "\C-z" 'undo)
(setq frame-title-format (concat "%b - emacs@" system-name))
(setq make-backup-files nil)
(setq kill-whole-line t)
(setq-default show-trailing-whitespace t)
(setq visible-bell t)

;; Always end a file with a newline.
;(setq require-final-newline t)


;=======================================================================
; Line truncation
;=======================================================================

; Do not wrap lines at the right edge.
(setq-default truncate-lines t)

; Do not wrap lines at the right edge of a horizontally split window.
(setq-default truncate-partial-width-windows t)

;(defun toggle-truncate-lines ()
;  (interactive)
;  (if truncate-lines
;      (setq truncate-lines nil)
;    (setq truncate-lines t))
;  (recenter))


;=======================================================================
; Saving the history
;=======================================================================
;(require 'session)
;(add-hook 'after-init-hook 'session-initialize)


;=======================================================================
; Recently used files
;=======================================================================
(recentf-mode t)


;=======================================================================
; Color regions
;=======================================================================
(transient-mark-mode t)


;=======================================================================
; Indicate the corresponding parenthesis
;=======================================================================
(show-paren-mode t)


;=======================================================================
; `C-c c` to invoke `compile` command
;=======================================================================
;(define-key mode-specific-map "c" 'compile)


;=======================================================================
; Automatically make script files executable
;=======================================================================
(defun make-file-executable ()
  "Make the file of this buffer executable, when it is a script source."
  (save-restriction
    (widen)
    (if (string= "#!"
         (buffer-substring-no-properties 1
                         (min 3 (point-max))))
        (let ((name (buffer-file-name)))
          (or (equal ?. (string-to-char
             (file-name-nondirectory name)))
              (let ((mode (file-modes name)))
                (set-file-modes name (logior mode (logand
                           (/ mode 4) 73)))
                (message (concat "Wrote " name " (+x)"))))))))
(add-hook 'after-save-hook 'make-file-executable)


;=======================================================================
; Add `~/.emacs.d/auto-install/` to the load path
;=======================================================================
(add-to-list 'load-path (expand-file-name "~/.emacs.d/auto-install"))
(add-to-list 'load-path "~/.emacs.d/lisp/")


;=======================================================================
; Indentation policy
;=======================================================================
(setq-default indent-tabs-mode nil)
(electric-indent-mode -1)


;=======================================================================
; Keyboard shortcuts
;=======================================================================
;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the right
;; under X, instead of the default, backspace behavior.
;(global-set-key [backspace] 'delete-backward-char)
;(global-set-key [delete] 'delete-char)
;(global-set-key "\C-h" 'delete-backward-char)
;(global-set-key "\M-?" 'help-for-help)
(global-set-key "\M-n" 'scroll-up)
(global-set-key "\M-p" 'scroll-down)
(global-set-key "\C-xn" (lambda () (interactive) (other-window 1)))
(global-set-key "\C-xp" (lambda () (interactive) (other-window -1)))

(defun split-window-vertically-n (n)
  (interactive "p")
  (if (= n 2)
      (split-window-vertically)
    (progn
      (split-window-vertically
       (- (window-height) (/ (window-height) n)))
      (split-window-vertically-n (- n 1)))))
(global-set-key "\C-x@" '(lambda ()
                           (interactive)
                           (split-window-vertically-n 3)))

(defun split-window-horizontally-n (n)
  (interactive "p")
  (if (= n 2)
      (split-window-horizontally)
    (progn
      (split-window-horizontally
       (- (window-width) (/ (window-width) n)))
      (split-window-horizontally-n (- n 1)))))
(global-set-key "\C-x#" '(lambda ()
                           (interactive)
                           (split-window-horizontally-n 3)))

(setq compile-command "bjam toolset=gcc-4.8.0")
(global-set-key [f1] 'compile)
(global-set-key [f2] 'previous-error)
(global-set-key [f3] 'next-error)

(global-set-key "\C-cl" 'toggle-truncate-lines)


(defun enable-electric-local-modes ()
  ; `electric-pair-local-mode` has been introduced since Emacs 25.1.
  (if (or (>= emacs-major-version 26)
          (and (= emacs-major-version 25)
               (>= emacs-minor-version 1)))
      (electric-pair-local-mode t)
    (electric-pair-mode t))
  ; `electric-indent-local-mode` has been introduced since Emacs 24.4.
  (if (or (>= emacs-major-version 25)
          (and (= emacs-major-version 24)
               (>= emacs-minor-version 4)))
      (electric-indent-local-mode t)
    (electric-indent-mode t)))

;=======================================================================
; Shell script mode
;=======================================================================
(add-hook 'sh-mode-hook
          '(lambda ()
             (progn
               (enable-electric-local-modes)
               (setq sh-basic-offset 2
                     sh-indentation 2
                     sh-indent-for-case-label 0
                     sh-indent-for-case-alt '+))))


;=======================================================================
; Python mode
;=======================================================================
(add-hook 'python-mode-hook
          '(lambda()
             (enable-electric-local-modes)))


;=======================================================================
; C/C++ modes
;=======================================================================
(require 'cc-mode)

(setq c-default-style "bsd")

(add-hook 'c-mode-common-hook
     	  '(lambda ()
             (enable-electric-local-modes)
             (setq c-basic-offset 2)
             (c-toggle-hungry-state t)
             (setq indent-tabs-mode nil)
             (setq show-trailing-whitespace t)))

(add-hook 'c++-mode-hook
          '(lambda ()
             (c-set-offset 'innamespace 0)))

(setq auto-mode-alist
      (append
       '(("\\.hpp$" . c++-mode)
         ("\\.cpp$" . c++-mode)
         ("\\.ipp$" . c++-mode)
         ) auto-mode-alist))


;=======================================================================
; YAML mode
;=======================================================================
(require 'yaml-mode)
(add-hook 'yaml-mode-hook
          '(lambda ()
             (enable-electric-local-modes)))


;=======================================================================
; CMake mode
;=======================================================================
(require 'cmake-mode)
(add-hook 'cmake-mode-hook
          '(lambda ()
             (enable-electric-local-modes)))
(setq auto-mode-alist
      (append
       '(("CMakeList\\.txt\\'", cmake-mode)
         ("\\.cmake\\'", cmake-mode))
       auto-mode-alist))


;=======================================================================
; Emacs Lisp mode
;=======================================================================
(add-hook 'emacs-lisp-mode-hook
          '(lambda ()
             (enable-electric-local-modes)))
