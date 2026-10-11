#!/usr/bin/env -S guile --no-auto-compile -s
!#
;;; List upstream commits newer than each commit-pinned channel in channels.scm.
;;; Usage: channel-updates [CHANNELS-FILE]   (default: ~/.dots/channels.scm)
;;; Keeps blobless bare clones in $XDG_CACHE_HOME/channel-updates/.

(use-modules (ice-9 match)
             (ice-9 popen)
             (ice-9 textual-ports)
             (srfi srfi-1))

(define home (getenv "HOME"))

(define channels-file
  (match (command-line)
    ((_ file . _) file)
    (_ (string-append home "/.dots/channels.scm"))))

(define cache-dir
  (string-append (or (getenv "XDG_CACHE_HOME") (string-append home "/.cache"))
                 "/channel-updates"))

;; Read channels.scm as data (no evaluation): (list (channel (field val) ...) ...)
(define (field ch key)
  (match (assq key (cdr ch))
    ((_ ('quote sym)) (symbol->string sym))
    ((_ val) val)
    (#f #f)))

(define pinned
  (match (call-with-input-file channels-file read)
    (('list channels ...)
     (filter (lambda (ch) (field ch 'commit)) channels))))

(define (git . args)
  "Run git, return trimmed stdout, or #f on failure."
  (let* ((port (apply open-pipe* OPEN_READ "git" args))
         (out (get-string-all port)))
    (and (zero? (status:exit-val (close-pipe port)))
         (string-trim-right out))))

(define (sync-repo name url branch)
  (let ((dir (string-append cache-dir "/" name ".git")))
    (if (file-exists? dir)
        (git "-C" dir "fetch" "--quiet" "--filter=blob:none"
             "origin" (string-append "+" branch ":" branch))
        (git "clone" "--quiet" "--bare" "--filter=blob:none" "--single-branch"
             "--branch" branch url dir))
    dir))

(system* "mkdir" "-p" cache-dir)

(when (null? pinned)
  (format #t "No commit-pinned channels in ~a~%" channels-file))

(for-each
 (lambda (ch)
   (let* ((name   (field ch 'name))
          (url    (field ch 'url))
          (branch (or (field ch 'branch) "master"))
          (commit (field ch 'commit))
          (dir    (sync-repo name url branch))
          (latest (git "-C" dir "rev-parse" branch)))
     (format #t "~a (~a)~%  pinned: ~a~%  latest: ~a~%"
             name branch commit (or latest "?? fetch failed"))
     (cond
      ((not latest) #t)
      ((string=? latest commit)
       (format #t "  up to date~%"))
      ((not (git "-C" dir "merge-base" "--is-ancestor" commit branch))
       (format #t "  pinned commit is not an ancestor of ~a (rewritten history?)~%"
               branch))
      (else
       (let ((log (git "-C" dir "log" "--format=%h %as %s"
                       (string-append commit ".." branch))))
         (format #t "  ~a new commit(s):~%"
                 (git "-C" dir "rev-list" "--count"
                      (string-append commit ".." branch)))
         (for-each (lambda (l) (format #t "    ~a~%" l))
                   (string-split log #\newline)))))
     (newline)))
 pinned)
