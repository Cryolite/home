;======================================================================
; 言語・文字コード関連の設定
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
;    CTRL-\で入力モード切替え
;======================================================================
;(load-library "anthy")
;(setq default-input-method "japanese-anthy")
;;
;=======================================================================
;フォント
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
;フレームサイズ・位置・色など
;=======================================================================
;(setq initial-frame-alist
;    (append (list
;           '(foreground-color . "white")        ;; 文字色
;           '(background-color . "#333366")        ;; 背景色
;           '(border-color . "black")
;           '(mouse-color . "white")
;           '(cursor-color . "white")
;           '(width . 90)                ;; フレームの幅
;           '(height . 49)                ;; フレームの高さ
;           '(top . 0)                    ;; Y 表示位置
;           '(left . 340)                ;; X 表示位置
;           )
;        initial-frame-alist))
;(setq default-frame-alist initial-frame-alist)
;;
;=======================================================================
; Misc
;=======================================================================
(mouse-wheel-mode)                        ;;ホイールマウス
(global-font-lock-mode t)                    ;;文字の色つけ
(setq line-number-mode t)                    ;;カーソルのある行番号を表示
(setq column-number-mode t)                  ;;カーソルのあるカラム番号を表示
(auto-compression-mode t)                    ;;日本語infoの文字化け防止
(set-scroll-bar-mode 'right)                    ;;スクロールバーを右に表示
;(global-set-key "\C-z" 'undo)                    ;;UNDO
(setq frame-title-format                    ;;フレームのタイトル指定
    (concat "%b - emacs@" system-name))

;(display-time)                            ;;時計を表示
;(global-set-key "\C-h" 'backward-delete-char)            ;;Ctrl-Hでバックスペース
;(setq make-backup-files nil)                    ;;バックアップファイルを作成しない
;(setq visible-bell t)                        ;;警告音を消す
;(setq kill-whole-line t)                    ;;カーソルが行頭にある場合も行全体を削除
;(when (boundp 'show-trailing-whitespace) (setq-default show-trailing-whitespace t))    ;;行末のスペースを強調表示
;;
;=======================================================================
; 履歴の保存
;=======================================================================
;(require 'session)
;(add-hook 'after-init-hook 'session-initialize)
;;
;=======================================================================
; 最近使ったファイル
;=======================================================================
(recentf-mode)
;;
;=======================================================================
; リージョンに色を付ける
;=======================================================================
(setq transient-mark-mode t)
;;
;=======================================================================
; 対応する括弧を光らせる
;=======================================================================
(show-paren-mode)
;;
;=======================================================================
; C-c c で compile コマンドを呼び出す 
;=======================================================================
;(define-key mode-specific-map "c" 'compile)
;;
;=======================================================================
; スクリプトを保存する時、自動的に chmod +x を行うようにする
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
; ~/.emacs.d/auto-install/ にパスを通す
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
(global-set-key "\M-n" 'scroll-up)
(global-set-key "\M-p" 'scroll-down)

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
