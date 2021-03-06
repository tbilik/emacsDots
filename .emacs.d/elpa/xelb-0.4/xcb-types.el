;;; xcb-types.el --- Type definitions for XCB  -*- lexical-binding: t -*-

;; Copyright (C) 2015 Free Software Foundation, Inc.

;; Author: Chris Feng <chris.w.feng@gmail.com>

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library defines various data types frequently used in XELB.  Simple
;; types are defined with `cl-deftype' while others are defined as classes.
;; Basically, data types are used for converting objects to/from byte arrays
;; rather than for validation purpose.  Classes defined elsewhere should also
;; support `xcb:marshal' and `xcb:unmarshal' methods in order to be considered
;; a type.  Most classes defined here are direct or indirect subclasses of
;; `xcb:-struct', which has implemented the fundamental marshalling and
;; unmarshalling methods.  These classes again act as the superclasses for more
;; concrete ones.  You may use `eieio-browse' to easily get an overview of the
;; inheritance hierarchies of all classes defined.

;; Please pay special attention to the byte order adopted in your application.
;; The global variable `xcb:lsb' specifies the byte order at the time of
;; instantiating a class (e.g. via `make-instance').  You may let-bind it to
;; temporarily change the byte order locally.

;; Todo:
;; + The current implementation of `eieio-default-eval-maybe' only `eval's a
;;   certain type of forms.  If this is changed in the future, we will have to
;;   adapt our codes accordingly.
;; + STRING16 and CHAR2B should always be big-endian.
;; + <paramref> for `xcb:-marshal-field'?

;; References:
;; + X protocol (http://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.txt)

;;; Code:

(require 'cl-lib)
(require 'cl-generic)
(require 'eieio)

;;;; Fix backward compatibility issues with Emacs < 25

;; Backport some new functions from Emacs 25

(eval-and-compile
  (unless (fboundp 'eieio-class-slots)
    (eval-and-compile
      (defun eieio-class-slots (class)
        (let* ((tmp (class-v class))
               (names (eieio--class-public-a tmp))
               (initforms (eieio--class-public-d tmp))
               (types (eieio--class-public-type tmp))
               result)
          (dotimes (i (length names))
            (setq result (nconc result (list (vector (elt names i)
                                                     (elt initforms i)
                                                     (elt types i))))))
          result)))))

(eval-and-compile
  (unless (fboundp 'eieio-slot-descriptor-name)
    (defsubst eieio-slot-descriptor-name (slot) (aref slot 0))))

(eval-when-compile
  (unless (fboundp 'cl--slot-descriptor-type)
    (defsubst cl--slot-descriptor-type (slot) (aref slot 2))))

;;;; Utility functions

(defsubst xcb:-pack-u1 (value)
  "1 byte unsigned integer => byte array."
  (vector value))

(defsubst xcb:-pack-i1 (value)
  "1 byte signed integer => byte array."
  (xcb:-pack-u1 (if (>= value 0) value
                  (1+ (logand #xFF (lognot (- value)))))))

(defsubst xcb:-pack-u2 (value)
  "2 bytes unsigned integer => byte array (MSB first)."
  (vector (logand (lsh value -8) #xFF) (logand value #xFF)))

(defsubst xcb:-pack-u2-lsb (value)
  "2 bytes unsigned integer => byte array (LSB first)."
  (vector (logand value #xFF) (logand (lsh value -8) #xFF)))

(defsubst xcb:-pack-i2 (value)
  "2 bytes signed integer => byte array (MSB first)."
  (xcb:-pack-u2 (if (>= value 0) value
                  (1+ (logand #xFFFF (lognot (- value)))))))

(defsubst xcb:-pack-i2-lsb (value)
  "2 bytes signed integer => byte array (LSB first)."
  (xcb:-pack-u2-lsb (if (>= value 0) value
                      (1+ (logand #xFFFF (lognot (- value)))))))

(eval-and-compile
  (if (/= 0 (lsh 1 32))
      ;; 64 bit
      (progn
        (defsubst xcb:-pack-u4 (value)
          "4 bytes unsigned integer => byte array (MSB first, 64-bit)."
          (vector (logand (lsh value -24) #xFF) (logand (lsh value -16) #xFF)
                  (logand (lsh value -8) #xFF) (logand value #xFF)))
        (defsubst xcb:-pack-u4-lsb (value)
          "4 byte unsigned integer => byte array (LSB first, 64-bit)."
          (vector (logand value #xFF)
                  (logand (lsh value -8) #xFF)
                  (logand (lsh value -16) #xFF)
                  (logand (lsh value -24) #xFF))))
    ;; 32 bit (30-bit actually; large numbers are represented as float type)
    (defsubst xcb:-pack-u4 (value)
      "4 bytes unsigned integer => byte array (MSB first, 32-bit)."
      (if (integerp value)
          (vector (logand (lsh value -24) #xFF) (logand (lsh value -16) #xFF)
                  (logand (lsh value -8) #xFF) (logand value #xFF))
        (let* ((msw (truncate value #x10000))
               (lsw (truncate (- value (* msw 65536.0)))))
          (vector (logand (lsh msw -8) #xFF) (logand msw #xFF)
                  (logand (lsh lsw -8) #xFF) (logand lsw #xFF)))))
    (defsubst xcb:-pack-u4-lsb (value)
      "4 bytes unsigned integer => byte array (LSB first, 32-bit)."
      (if (integerp value)
          (vector (logand value #xFF) (logand (lsh value -8) #xFF)
                  (logand (lsh value -16) #xFF) (logand (lsh value -24) #xFF))
        (let* ((msw (truncate value #x10000))
               (lsw (truncate (- value (* msw 65536.0)))))
          (vector (logand lsw #xFF) (logand (lsh lsw -8) #xFF)
                  (logand msw #xFF) (logand (lsh msw -8) #xFF)))))))

(defsubst xcb:-pack-i4 (value)
  "4 bytes signed integer => byte array (MSB first)."
  (xcb:-pack-u4 (if (>= value 0)
                    value
                  (+ value #x100000000)))) ;treated as float for 32-bit

(defsubst xcb:-pack-i4-lsb (value)
  "4 bytes signed integer => byte array (LSB first)."
  (xcb:-pack-u4-lsb (if (>= value 0)
                        value
                      (+ value #x100000000)))) ;treated as float for 32-bit

(defsubst xcb:-unpack-u1 (data offset)
  "Byte array => 1 byte unsigned integer."
  (aref data offset))

(defsubst xcb:-unpack-i1 (data offset)
  "Byte array => 1 byte signed integer."
  (let ((value (xcb:-unpack-u1 data offset)))
    (if (= 0 (logand #x80 value))
        value
      (- (logand #xFF (lognot (1- value)))))))

(defsubst xcb:-unpack-u2 (data offset)
  "Byte array => 2 bytes unsigned integer (MSB first)."
  (logior (lsh (aref data offset) 8) (aref data (1+ offset))))

(defsubst xcb:-unpack-u2-lsb (data offset)
  "Byte array => 2 bytes unsigned integer (LSB first)."
  (logior (aref data offset) (lsh (aref data (1+ offset)) 8)))

(defsubst xcb:-unpack-i2 (data offset)
  "Byte array => 2 bytes signed integer (MSB first)."
  (let ((value (xcb:-unpack-u2 data offset)))
    (if (= 0 (logand #x8000 value))
        value
      (- (logand #xFFFF (lognot (1- value)))))))

(defsubst xcb:-unpack-i2-lsb (data offset)
  "Byte array => 2 bytes signed integer (LSB first)."
  (let ((value (xcb:-unpack-u2-lsb data offset)))
    (if (= 0 (logand #x8000 value))
        value
      (- (logand #xFFFF (lognot (1- value)))))))

(eval-and-compile
  (if (/= 0 (lsh 1 32))
      ;; 64-bit
      (progn
        (defsubst xcb:-unpack-u4 (data offset)
          "Byte array => 4 bytes unsigned integer (MSB first, 64-bit)."
          (logior (lsh (aref data offset) 24) (lsh (aref data (1+ offset)) 16)
                  (lsh (aref data (+ offset 2)) 8) (aref data (+ offset 3))))
        (defsubst xcb:-unpack-u4-lsb (data offset)
          "Byte array => 4 bytes unsigned integer (LSB first, 64-bit)."
          (logior (aref data offset) (lsh (aref data (1+ offset)) 8)
                  (lsh (aref data (+ offset 2)) 16)
                  (lsh (aref data (+ offset 3)) 24))))
    ;; 32-bit (30-bit actually; large numbers are represented as float type)
    (defsubst xcb:-unpack-u4 (data offset)
      "Byte array => 4 bytes unsigned integer (MSB first, 32-bit)."
      (let ((msb (aref data offset)))
        (+ (if (> msb 31) (* msb 16777216.0) (lsh msb 24))
           (logior (lsh (aref data (1+ offset)) 16)
                   (lsh (aref data (+ offset 2)) 8)
                   (aref data (+ offset 3))))))
    (defsubst xcb:-unpack-u4-lsb (data offset)
      "Byte array => 4 bytes unsigned integer (LSB first, 32-bit)."
      (let ((msb (aref data (+ offset 3))))
        (+ (if (> msb 31) (* msb 16777216.0) (lsh msb 24))
           (logior (aref data offset)
                   (lsh (aref data (1+ offset)) 8)
                   (lsh (aref data (+ offset 2)) 16)))))))

(defsubst xcb:-unpack-i4 (data offset)
  "Byte array => 4 bytes signed integer (MSB first)."
  (let ((value (xcb:-unpack-u4 data offset)))
    (if (< value #x80000000)            ;treated as float for 32-bit
        value
      (- value #x100000000))))          ;treated as float for 32-bit

(defsubst xcb:-unpack-i4-lsb (data offset)
  "Byte array => 4 bytes signed integer (LSB first)."
  (let ((value (xcb:-unpack-u4-lsb data offset)))
    (if (< value #x80000000)            ;treated as float for 32-bit
        value
      (- value #x100000000))))          ;treated as float for 32-bit

(defmacro xcb:-fieldref (field)
  "Evaluate a <fieldref> field."
  `(slot-value obj ,field))

(defmacro xcb:-paramref (field)
  "Evaluate a <paramref> field."
  `(slot-value ctx ,field))

(defsubst xcb:-popcount (mask)
  "Return the popcount of integer MASK."
  (apply #'+ (mapcar (lambda (i)
                       (logand (lsh mask i) 1))
                     ;; 32-bit number assumed (CARD32)
                     (eval-when-compile (number-sequence -31 0)))))

(defsubst xcb:-request-class->reply-class (request)
  "Return the reply class corresponding to the request class REQUEST."
  (intern-soft (concat (symbol-name request) "~reply")))

;;;; Basic types

;; typedef in C
(defmacro xcb:deftypealias (new-type old-type)
  "Define NEW-TYPE as an alias of type OLD-TYPE."
  `(progn
     (cl-deftype ,(eval new-type) nil ,old-type)
     (defvaralias ,new-type ,old-type)))

;; 1/2/4 B signed/unsigned integer
(cl-deftype xcb:-i1 () t)
(cl-deftype xcb:-i2 () t)
(cl-deftype xcb:-i4 () t)
(cl-deftype xcb:-u1 () t)
(cl-deftype xcb:-u2 () t)
(cl-deftype xcb:-u4 () t)
;; <pad>
(cl-deftype xcb:-pad () t)
;; <pad> with align attribute
(cl-deftype xcb:-pad-align () t)
;; <fd>
(cl-deftype xcb:-fd () t)
;; <list>
(cl-deftype xcb:-list () t)
;; <switch>
(cl-deftype xcb:-switch () t)
;; This type of data is not involved in marshalling/unmarshalling
(cl-deftype xcb:-ignore () t)
;; C types and types missing in XCB
(cl-deftype xcb:void () t)
(xcb:deftypealias 'xcb:char 'xcb:-u1)
(xcb:deftypealias 'xcb:BYTE 'xcb:-u1)
(xcb:deftypealias 'xcb:INT8 'xcb:-i1)
(xcb:deftypealias 'xcb:INT16 'xcb:-i2)
(xcb:deftypealias 'xcb:INT32 'xcb:-i4)
(xcb:deftypealias 'xcb:CARD8 'xcb:-u1)
(xcb:deftypealias 'xcb:CARD16 'xcb:-u2)
(xcb:deftypealias 'xcb:CARD32 'xcb:-u4)
(xcb:deftypealias 'xcb:BOOL 'xcb:-u1)

;;;; Struct type

(eval-and-compile
  (defvar xcb:lsb t
    "Non-nil for LSB first (i.e., little-endian), nil otherwise.

Consider let-bind it rather than change its global value."))

(defclass xcb:-struct ()
  ((~lsb :initarg :~lsb
         :initform (symbol-value 'xcb:lsb) ;see `eieio-default-eval-maybe'
         :type xcb:-ignore))
  :documentation "Struct type.")

(cl-defmethod xcb:marshal ((obj xcb:-struct))
  "Return the byte-array representation of struct OBJ."
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        result name type value)
    (catch 'break
      (dolist (slot slots)
        (setq type (cl--slot-descriptor-type slot))
        (unless (or (eq type 'fd) (eq type 'xcb:-ignore))
          (setq name (eieio-slot-descriptor-name slot))
          (setq value (slot-value obj name))
          (when (symbolp value)        ;see `eieio-default-eval-maybe'
            (setq value (symbol-value value)))
          (setq result
                (vconcat result (xcb:-marshal-field obj type value
                                                    (length result))))
          (when (eq type 'xcb:-switch) ;xcb:-switch always finishes a struct
            (throw 'break 'nil)))))
    result))

(cl-defmethod xcb:-marshal-field ((obj xcb:-struct) type value &optional pos)
  "Return the byte-array representation of a field in struct OBJ of type TYPE
and value VALUE.

The optional POS argument indicates current byte index of the field (used by
`xcb:-pad-align' type)."
  (pcase (indirect-variable type)
    (`xcb:-u1 (xcb:-pack-u1 value))
    (`xcb:-i1 (xcb:-pack-i1 value))
    (`xcb:-u2
     (if (slot-value obj '~lsb) (xcb:-pack-u2-lsb value) (xcb:-pack-u2 value)))
    (`xcb:-i2
     (if (slot-value obj '~lsb) (xcb:-pack-i2-lsb value) (xcb:-pack-i2 value)))
    (`xcb:-u4
     (if (slot-value obj '~lsb) (xcb:-pack-u4-lsb value) (xcb:-pack-u4 value)))
    (`xcb:-i4
     (if (slot-value obj '~lsb) (xcb:-pack-i4-lsb value) (xcb:-pack-i4 value)))
    (`xcb:void (vector value))
    (`xcb:-pad
     (unless (integerp value)
       (setq value (eval value `((obj . ,obj)))))
     (make-vector value 0))
    (`xcb:-pad-align
     (unless (integerp value)
       (setq value (eval value `((obj . ,obj)))))
     ;; The length slot in xcb:-request is left out
     (let ((len (if (object-of-class-p obj 'xcb:-request) (+ pos 2) pos)))
       (make-vector (% (- value (% len value)) value) 0)))
    (`xcb:-list
     (let* ((list-name (plist-get value 'name))
            (list-type (plist-get value 'type))
            (list-size (plist-get value 'size))
            (data (slot-value obj list-name)))
       (unless (integerp list-size)
         (setq list-size (eval list-size `((obj . ,obj))))
         (unless list-size
           (setq list-size (length data)))) ;list-size can be nil
       (cl-assert (= list-size (length data)))
       (mapconcat (lambda (i) (xcb:-marshal-field obj list-type i)) data [])))
    (`xcb:-switch
     (let ((slots (eieio-class-slots (eieio-object-class obj)))
           (expression (plist-get value 'expression))
           (cases (plist-get value 'cases))
           result condition name-list flag slot-type)
       (unless (integerp expression)
         (setq expression (eval expression `((obj . ,obj)))))
       (cl-assert (integerp expression))
       (dolist (i cases)
         (setq condition (car i))
         (setq name-list (cdr i))
         (setq flag nil)
         (if (symbolp condition)
             (setq condition (symbol-value condition))
           (when (and (listp condition) (eq 'logior (car condition)))
             (setq condition (apply #'logior (cdr condition)))))
         (cl-assert (or (integerp condition) (listp condition)))
         (if (integerp condition)
             (setq flag (/= 0 (logand expression condition)))
           (while (and (not flag) condition)
             (setq flag (or flag (= expression (pop condition))))))
         (when flag
           (dolist (name name-list)
             (catch 'break
               (dolist (slot slots) ;better way to find the slot type?
                 (when (eq name (eieio-slot-descriptor-name slot))
                   (setq slot-type (cl--slot-descriptor-type slot))
                   (throw 'break nil))))
             (setq result
                   (vconcat result
                            (xcb:-marshal-field obj slot-type
                                                (slot-value obj name)
                                                (+ pos (length result))))))))
       result))
    ((guard (child-of-class-p type 'xcb:-struct))
     (xcb:marshal value))
    (x (error "[XCB] Unsupported type for marshalling: %s" x))))

(cl-defmethod xcb:unmarshal ((obj xcb:-struct) byte-array &optional ctx)
  "Fill in fields of struct OBJ according to its byte-array representation.

The optional argument CTX is for <paramref>."
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        (result 0)
        slot-name tmp type)
    (dolist (slot slots)
      (setq type (cl--slot-descriptor-type slot))
      (unless (or (eq type 'fd) (eq type 'xcb:-ignore))
        (setq slot-name (eieio-slot-descriptor-name slot)
              tmp (xcb:-unmarshal-field obj type byte-array 0
                                        (when (slot-boundp obj slot-name)
                                          (eieio-oref-default obj slot-name))
                                        ctx))
        (setf (slot-value obj slot-name) (car tmp))
        (setq byte-array (substring byte-array (cadr tmp)))
        (setq result (+ result (cadr tmp)))))
    result))

(cl-defmethod xcb:-unmarshal-field ((obj xcb:-struct) type data offset
                                    initform &optional ctx)
  "Return the value of a field in struct OBJ of type TYPE, byte-array
representation DATA, and default value INITFORM.

The optional argument CTX is for <paramref>.

This method returns a list of two components, with the first being the result
and the second the consumed length."
  (pcase (indirect-variable type)
    (`xcb:-u1 (list (aref data offset) 1))
    (`xcb:-i1 (let ((result (aref data offset)))
                (list (if (< result 128) result (- result 255)) 1)))
    (`xcb:-u2 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-u2-lsb data offset)
                      (xcb:-unpack-u2 data offset))
                    2))
    (`xcb:-i2 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-i2-lsb data offset)
                      (xcb:-unpack-i2 data offset))
                    2))
    (`xcb:-u4 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-u4-lsb data offset)
                      (xcb:-unpack-u4 data offset))
                    4))
    (`xcb:-i4 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-i4-lsb data offset)
                      (xcb:-unpack-i4 data offset))
                    4))
    (`xcb:void (list (aref data offset) 1))
    (`xcb:-pad
     (unless (integerp initform)
       (when (eq 'quote (car initform))
         (setq initform (cadr initform)))
       (setq initform (eval initform `((obj . ,obj) (ctx . ,ctx)))))
     (list initform initform))
    (`xcb:-pad-align                 ;assume the whole data is aligned
     (unless (integerp initform)
       (when (eq 'quote (car initform))
         (setq initform (cadr initform)))
       (setq initform (eval initform `((obj . ,obj) (ctx . ,ctx)))))
     (list initform (% (- (length data) offset) initform)))
    (`xcb:-list
     (when (eq 'quote (car initform))   ;unquote the form
       (setq initform (cadr initform)))
     (let ((list-name (plist-get initform 'name))
           (list-type (plist-get initform 'type))
           (list-size (plist-get initform 'size)))
       (unless (integerp list-size)
         (setq list-size (eval list-size `((obj . ,obj) (ctx . ,ctx)))))
       (cl-assert (integerp list-size))
       (pcase list-type
         (`xcb:char                     ;as Latin-1 encoded string
          (setf (slot-value obj list-name)
                (decode-coding-string
                 (apply #'unibyte-string
                        (append (substring data offset
                                           (+ offset list-size))
                                nil))
                 'iso-latin-1)))
         (`xcb:void                     ;for further unmarshalling
          (setf (slot-value obj list-name)
                (substring data offset (+ offset list-size))))
         (x
          (let ((count 0)
                result tmp)
            (dotimes (_ list-size)
              (setq tmp (xcb:-unmarshal-field obj x data (+ offset count) nil))
              (setq result (nconc result (list (car tmp))))
              (setq count (+ count (cadr tmp))))
            (setf (slot-value obj list-name) result)
            (setq list-size count))))   ;to byte length
       (list initform list-size)))
    (`xcb:-switch
     (let ((slots (eieio-class-slots (eieio-object-class obj)))
           (expression (plist-get initform 'expression))
           (cases (plist-get initform 'cases))
           (count 0)
           condition name-list flag slot-type tmp)
       (unless (integerp expression)
         (setq expression (eval expression `((obj . ,obj) (ctx . ,ctx)))))
       (cl-assert (integerp expression))
       (dolist (i cases)
         (setq condition (car i))
         (setq name-list (cdr i))
         (setq flag nil)
         (if (integerp condition)
             (setq flag (/= 0 (logand expression condition)))
           (if (eq 'logior (car condition))
               (setq flag (/= 0 (logand expression
                                        (apply #'logior (cdr condition)))))
             (while (and (not flag) condition)
               (setq flag (or flag (= expression (pop condition)))))))
         (when flag
           (dolist (name name-list)
             (catch 'break
               (dolist (slot slots) ;better way to find the slot type?
                 (when (eq name (eieio-slot-descriptor-name slot))
                   (setq slot-type (cl--slot-descriptor-type slot))
                   (throw 'break nil))))
             (setq tmp (xcb:-unmarshal-field obj slot-type data offset nil))
             (setf (slot-value obj name) (car tmp))
             (setq count (+ count (cadr tmp)))
             (setq data (substring data (cadr tmp))))))
       (list initform count)))
    ((and x (guard (child-of-class-p x 'xcb:-struct)))
     (let* ((struct-obj (make-instance x))
            (tmp (xcb:unmarshal struct-obj (substring data offset) obj)))
       (list struct-obj tmp)))
    (x (error "[XCB] Unsupported type for unmarshalling: %s" x))))

;;;; Types derived directly from `xcb:-struct'

(defclass xcb:-request (xcb:-struct)
  nil
  :documentation "X request type.")

(defclass xcb:-reply (xcb:-struct)
  ((length :initarg :length ;reply length, used in e.g. GetKeyboardMapping
           :type xcb:-ignore))
  :documentation "X reply type.")
;;
(cl-defmethod xcb:unmarshal ((obj xcb:-reply) byte-array)
  "Fill in fields in a reply OBJ according to its byte-array representation."
  (cl-call-next-method obj (vconcat (substring byte-array 1 2)
                                    (substring byte-array 8))))

(defclass xcb:-event (xcb:-struct)
  nil
  :documentation "Event type.")
;; Implemented in 'xcb.el'
(cl-defgeneric xcb:-error-or-event-class->number ((obj xcb:connection) class))
;;
(cl-defmethod xcb:marshal ((obj xcb:-event) connection &optional sequence)
  "Return the byte-array representation of event OBJ.

This method is mainly designed for `xcb:SendEvent', where it's used to generate
synthetic events. The CONNECTION argument is used to retrieve the event number
for extensions. If SEQUENCE is non-nil, it is used as the sequence number in
the synthetic event. Otherwise, 0 is assumed.

Note that this method auto pads the result to 32 bytes, as is always the case."
  (let ((result (cl-call-next-method obj)))
    (setq result (vconcat
                  `[,(xcb:-error-or-event-class->number ;defined in 'xcb.el'
                      connection (eieio-object-class obj))]
                  result))
    (unless (same-class-p obj 'xcb:KeymapNotify)
      (setq result
            (vconcat (substring result 0 2)
                     (funcall (if (slot-value obj '~lsb) #'xcb:-pack-u2-lsb
                                #'xcb:-pack-u2)
                              (or sequence 0))
                     (substring result 2))))
    (cl-assert (>= 32 (length result)))
    (setq result (vconcat result (make-vector (- 32 (length result)) 0)))))
;;
(cl-defmethod xcb:unmarshal ((obj xcb:-event) byte-array)
  "Fill in event OBJ according to its byte-array representation BYTE-ARRAY."
  (cl-call-next-method obj
                       (if (same-class-p obj 'xcb:KeymapNotify)
                           (substring byte-array 1) ;strip event code
                         ;; Strip event code & sequence number
                         (vconcat (substring byte-array 1 2)
                                  (substring byte-array 4)))))

(defclass xcb:-error (xcb:-struct)
  nil
  :documentation "X error type.")
;;
(cl-defmethod xcb:unmarshal ((obj xcb:-error) byte-array)
  "Fill in error OBJ according to its byte-array representation BYTE-ARRAY."
  (cl-call-next-method obj (substring byte-array 4))) ;skip the first 4 bytes

(defclass xcb:-union (xcb:-struct)
  nil
  :documentation "Union type.")
;;
(cl-defmethod xcb:marshal ((obj xcb:-union))
  "Return the byte-array representation of union OBJ.

This result is converted from the first bounded slot."
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        result slot type name)
    (while (and (not result) slots)
      (setq slot (pop slots))
      (setq type (cl--slot-descriptor-type slot)
            name (eieio-slot-descriptor-name slot))
      (unless (or (not (slot-boundp obj name))
                  (eq type 'xcb:-ignore)
                  ;; Dealing with `xcb:-list' type
                  (and (eq type 'xcb:-list)
                       (not (slot-boundp obj (plist-get (slot-value obj name)
                                                        'name)))))
        (setq result (xcb:-marshal-field obj
                                         (cl--slot-descriptor-type slot)
                                         (slot-value obj name)))))
    result))
;;
(cl-defmethod xcb:unmarshal ((obj xcb:-union) byte-array &optional ctx)
  "Fill in every field in union OBJ, according to BYTE-ARRAY.

The optional argument CTX is for <paramref>."
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        slot-name consumed tmp type)
    (dolist (slot slots)
      (setq type (cl--slot-descriptor-type slot))
      (unless (eq type 'xcb:-ignore)
        (setq slot-name (eieio-slot-descriptor-name slot)
              tmp (xcb:-unmarshal-field obj type byte-array 0
                                        (when (slot-boundp obj slot-name)
                                          (eieio-oref-default obj slot-name))
                                        ctx))
        (setf (slot-value obj (eieio-slot-descriptor-name slot)) (car tmp))
        (setq consumed (cadr tmp))))
    consumed))                          ;consume byte-array only once



(provide 'xcb-types)

;;; xcb-types.el ends here
