;======================================================================
; ���졦ʸ�������ɴ�Ϣ������
;======================================================================
(when (equal emacs-major-version 21) (require 'un-define))
(set-language-environment "Japanese")
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(setq file-name-coding-system 'utf-8)
;;
;======================================================================
; Anthy
;    CTRL-\�����ϥ⡼�����ؤ�
;======================================================================
;(load-library "anthy")
;(setq default-input-method "japanese-anthy")
;;
;=======================================================================
;�ե����
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
;;
;=======================================================================
;�ե졼�ॵ���������֡����ʤ�
;=======================================================================
;(setq initial-frame-alist
;    (append (list
;           '(foreground-color . "white")        ;; ʸ����
;           '(background-color . "#333366")        ;; �طʿ�
;           '(border-color . "black")
;           '(mouse-color . "white")
;           '(cursor-color . "white")
;           '(width . 90)                ;; �ե졼�����
;           '(height . 49)                ;; �ե졼��ι⤵
;           '(top . 0)                    ;; Y ɽ������
;           '(left . 340)                ;; X ɽ������
;           )
;        initial-frame-alist))
;(setq default-frame-alist initial-frame-alist)
;;
;=======================================================================
; Misc
;=======================================================================
(mouse-wheel-mode)                        ;;�ۥ�����ޥ���
(global-font-lock-mode t)                    ;;ʸ���ο��Ĥ�
(setq line-number-mode t)                    ;;��������Τ�����ֹ��ɽ��
(auto-compression-mode t)                    ;;���ܸ�info��ʸ�������ɻ�
(set-scroll-bar-mode 'right)                    ;;��������С��򱦤�ɽ��
;(global-set-key "\C-z" 'undo)                    ;;UNDO
(setq frame-title-format                    ;;�ե졼��Υ����ȥ����
    (concat "%b - emacs@" system-name))

;(display-time)                            ;;���פ�ɽ��
;(global-set-key "\C-h" 'backward-delete-char)            ;;Ctrl-H�ǥХå����ڡ���
;(setq make-backup-files nil)                    ;;�Хå����åץե������������ʤ�
;(setq visible-bell t)                        ;;�ٹ𲻤�ä�
;(setq kill-whole-line t)                    ;;�������뤬��Ƭ�ˤ����������Τ���
;(when (boundp 'show-trailing-whitespace) (setq-default show-trailing-whitespace t))    ;;�����Υ��ڡ�����Ĵɽ��
;;
;=======================================================================
; �������¸
;=======================================================================
;(require 'session)
;(add-hook 'after-init-hook 'session-initialize)
;;
;=======================================================================
; �Ƕ�Ȥä��ե�����
;=======================================================================
(recentf-mode)
;;
;=======================================================================
; �꡼�����˿����դ���
;=======================================================================
(setq transient-mark-mode t)
;;
;=======================================================================
; �б������̤���餻��
;=======================================================================
;(show-paren-mode)
;;
;=======================================================================
; C-c c �� compile ���ޥ�ɤ�ƤӽФ� 
;=======================================================================
;(define-key mode-specific-map "c" 'compile)
;;
;=======================================================================
; ������ץȤ���¸���������ưŪ�� chmod +x ��Ԥ��褦�ˤ���
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
;;
;=======================================================================
; ~/.emacs.d/auto-install/ �˥ѥ����̤�
;=======================================================================
(add-to-list 'load-path (expand-file-name "~/.emacs.d/auto-install"))
;;
;=======================================================================
; End of File
;=======================================================================


;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the right
;; under X, instead of the default, backspace behavior.
;(global-set-key [backspace] 'delete-backward-char)
;(global-set-key [delete] 'delete-char)
;(global-set-key "\C-h" 'delete-backward-char)
;(global-set-key "\M-?" 'help-for-help)
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

(setq truncate-lines nil)
(setq truncate-partial-width-windows nil)

;(defun toggle-truncate-lines ()
;  (interactive)
;  (if truncate-lines
;      (setq truncate-lines nil)
;    (setq truncate-lines t))
;  (recenter))

(global-set-key "\C-cl" 'toggle-truncate-lines)

;; always end a file with a newline
;(setq require-final-newline t)

;;; Hacked by Ai Azuma. 2003/12/06.
(set-background-color "black")
(set-foreground-color "white")
(set-cursor-color "white")


(require 'cc-mode)

;; Kernighan & Ritchie style
(setq c-default-style "k&r")

(add-hook 'c-mode-common-hook
     	  '(lambda ()
             (progn
               (c-toggle-hungry-state 1)
               (setq c-basic-offset 2 indent-tabs-mode nil))))

(setq auto-mode-alist
      (append
       '(("\\.hpp$" . c++-mode)
         ("\\.cpp$" . c++-mode)
         ) auto-mode-alist))
