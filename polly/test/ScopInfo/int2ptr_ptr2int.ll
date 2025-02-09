; RUN: opt %loadNPMPolly '-passes=print<polly-function-scops>' -disable-output < %s 2>&1 | FileCheck %s
; RUN: opt %loadNPMPolly -S -passes=polly-codegen < %s 2>&1 | FileCheck %s --check-prefix=IR
;
;    void f(long *A, long *ptr, long val) {
;      for (long i = 0; i < 100; i++) {
;        long ptrV = ((long)(ptr + 1)) + 1;
;        long valP = (long)(((long *)(val + 1)) + 1);
;        A[ptrV] += A[valP];
;      }
;    }
;
; CHECK:        ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:       [val, ptr] -> { Stmt_for_body[i0] -> MemRef_A[9 + val] };
; CHECK-NEXT:   ReadAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:       [val, ptr] -> { Stmt_for_body[i0] -> MemRef_A[9 + ptr] };
; CHECK-NEXT:   MustWriteAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:       [val, ptr] -> { Stmt_for_body[i0] -> MemRef_A[9 + ptr] };
;
; IR:      entry:
; IR-NEXT:   %ptr1 = ptrtoint ptr %ptr to i32
;
; IR:      polly.stmt.for.body:
; IR-NEXT:   %p_tmp1 = inttoptr i64 %14 to ptr
; IR-NEXT:   %p_add.ptr2 = getelementptr inbounds i64, ptr %p_tmp1, i64 1
; IR-NEXT:   %p_tmp2 = ptrtoint ptr %p_add.ptr2 to i64
; IR-NEXT:   %p_arrayidx = getelementptr inbounds i64, ptr %A, i64 %p_tmp2
; IR-NEXT:   %tmp3_p_scalar_ = load i64, ptr %p_arrayidx, align 8, !alias.scope !2, !noalias !5
; IR-NEXT:   %tmp4_p_scalar_ = load i64, ptr %scevgep, align 8, !alias.scope !2, !noalias !5
; IR-NEXT:   %p_add4 = add nsw i64 %tmp4_p_scalar_, %tmp3_p_scalar_
; IR-NEXT:   store i64 %p_add4, ptr %scevgep, align 8, !alias.scope !2, !noalias !5
; IR-NEXT:   %polly.indvar_next = add nsw i64 %polly.indvar, 1
; IR-NEXT:   %polly.loop_cond = icmp sle i64 %polly.indvar_next, 99
; IR-NEXT:   br i1 %polly.loop_cond, label %polly.loop_header, label %polly.loop_exit
;
; IR:      polly.loop_preheader:
; IR-NEXT:   %14 = add i64 %val, 1
; IR-NEXT:   %15 = shl i32 %ptr1, 3
; IR-NEXT:   %16 = add i32 %15, 72
; IR-NEXT:   %scevgep = getelementptr i8, ptr %A, i32 %16
; IR-NEXT:   br label %polly.loop_header

;
target datalayout = "e-p:32:32:32-m:e-i64:64-f80:128-n8:16:32:64-S128"

define void @f(ptr %A, ptr %ptr, i64 %val) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i64 [ 0, %entry ], [ %inc, %for.inc ]
  %exitcond = icmp ne i64 %i.0, 100
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %add.ptr = getelementptr inbounds i64, ptr %ptr, i64 1
  %tmp = ptrtoint ptr %add.ptr to i64
  %add = add nsw i64 %tmp, 1
  %add1 = add nsw i64 %val, 1
  %tmp1 = inttoptr i64 %add1 to ptr
  %add.ptr2 = getelementptr inbounds i64, ptr %tmp1, i64 1
  %tmp2 = ptrtoint ptr %add.ptr2 to i64
  %arrayidx = getelementptr inbounds i64, ptr %A, i64 %tmp2
  %tmp3 = load i64, ptr %arrayidx
  %arrayidx3 = getelementptr inbounds i64, ptr %A, i64 %add
  %tmp4 = load i64, ptr %arrayidx3
  %add4 = add nsw i64 %tmp4, %tmp3
  store i64 %add4, ptr %arrayidx3
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nuw nsw i64 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}
