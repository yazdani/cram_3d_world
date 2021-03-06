;;;
;;; Copyright (c) 2014, Gayane Kazhoyan <kazhoyan@cs.uni-bremen.de>
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;;
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright
;;;       notice, this list of conditions and the following disclaimer in the
;;;       documentation and/or other materials provided with the distribution.
;;;     * Neither the name of the Institute for Artificial Intelligence/
;;;       Universitaet Bremen nor the names of its contributors may be used to
;;;       endorse or promote products derived from this software without
;;;       specific prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :bullet-reasoning-utilities)

(defgeneric spawn-object (name type &key pose color world)
  (:method (name type &key pose color world)
    (var-value
   '?object-instance
   (car (prolog
         `(and
           ,(if pose
                `(equal ?pose ,pose)
                `(scenario-objects-init-pose ?pose))
           ,(if color
                `(equal ?color ,color)
                `(scenario-object-color ?_ ,type ?color))
           ,(if world
                `(equal ?world ,world)
                `(bullet-world ?world))
           (scenario-object-shape ,type ?shape)
           (scenario-object-extra-attributes ?_ ,type ?attributes)
           (append (object ?world ?shape ,name ?pose :mass 0.2 :color ?color) ?attributes
                   ?object-description)
           (assert ?object-description)
           (%object ?world ,name ?object-instance)))))))

(defgeneric kill-object (name)
  (:method (name)
    (prolog-?w `(retract (object ?w ,name)))))

(defgeneric kill-all-objects ()
  (:method ()
    (prolog-?w `(household-object-type ?w ?obj ?type) `(retract (object ?w ?obj)) '(fail))))

(defun move-object (object-name &optional new-pose)
  (if new-pose
      (prolog-?w
        `(assert (object-pose ?w ,object-name ,new-pose)))
      (prolog-?w
        '(scenario-objects-init-pose ?pose)
        `(assert (object-pose ?w ,object-name ?pose)))))

(defun move-object-onto (object-name onto-type &optional onto-name)
  (let* ((size
           (cl-bullet:bounding-box-dimensions (aabb (object-instance object-name))))
         (obj-diagonal-len
           (sqrt (+ (expt (cl-transforms:x size) 2) (expt (cl-transforms:y size) 2))))
         (on-designator
           (make-designator :location `((:on ,onto-type)
                                        ,(when onto-name (list :name onto-name))
                                        (:centered-with-padding ,obj-diagonal-len)))))
    (prolog
     `(assert-object-pose-on ,object-name ,on-designator))))

(defun object-instance (object-name)
  (var-value '?instance
             (car (prolog-?w `(%object ?w ,object-name ?instance)))))

(defun object-pose (object-name)
  (pose (object-instance object-name)))

(defun object-exists (object-name)
  (typep (object-instance object-name) 'btr:object))

(defun household-object-exists (object-name)
  (typep (object-instance object-name) 'btr:household-object))

(declaim (inline move-object object-instance object-pose
                 object-exists household-object-exists))


;;;;;;;;;;;;;;;;;;;; PROLOG ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def-fact-group bullet-reasoning-utilities ()
  (<- (assert-object-pose ?obj-name ?desig)
    (once
     (bound ?obj-name)
     (bound ?desig)
     (bullet-world ?w)
     (desig-solutions ?desig ?solutions)
     (take 1 ?solutions ?8-solutions)
     (generate-values ?poses-on (obj-poses-on ?obj-name ?8-solutions ?w))
     (member ?solution ?poses-on)
     (assert (object-pose ?w ?obj-name ?solution))))

  (<- (assert-object-pose-on ?obj-name ?desig)
    (once
     (bound ?obj-name)
     (bound ?desig)
     (bullet-world ?w)
     (desig-solutions ?desig ?solutions)
     (take 8 ?solutions ?8-solutions)
     (member ?solution ?8-solutions)
     (assert (object-pose-on ?w ?obj-name ?solution)))))

