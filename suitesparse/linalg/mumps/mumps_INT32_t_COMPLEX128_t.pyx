"""
This is the interface to MUMPS (http://mumps.enseeiht.fr/index.php?page=home)

"""

"""
Some notes for the maintainers of this library.

Basic working:
--------------

MUMPS working is simple:

- initialize/modify the C struct MUMPS_STRUC_C;
- call mumps_c(MUMPS_STRUC_C *).

For example:

# analyze
MUMPS_STRUC_C.job = 1
mumps_c(&MUMPS_STRUC_C)

# factorize
MUMPS_STRUC_C.job = 2
mumps_c(&MUMPS_STRUC_C)

# solve
MUMPS_STRUC_C.job = 3
mumps_c(&MUMPS_STRUC_C)

etc.

Access to:
 - icntl
 - info
 - infog
 - cntl
 - rinfo
 - rinfog

**must** be done through properties!!!!


Typed C struct:
---------------

Each MUMPS_STRUC_C is specialized and prefixed by a letter:

- SMUMPS_STRUC_C: simple precision;
- DMUMPS_STRUC_C: double precision;
- CMUMPS_STRUC_C: simple complex;
- ZMUMPS_STRUC_C: double complex.

In CySparse (MUMPSContext_INT32_t_COMPLEX128_t), Xmumps_c() is called by a call to self.mumps_call().

<ZMUMPS_COMPLEX *> can be used for **ALL** four types.

CySparse complex type **IS** compatible with MUMPS_COMPLEX struct (both use C99 complex types).

Solve:
------

MUMPS **overwrites** the rhs member and replaces it by the solution(s) it finds. If sparse solve is used, the solution
is placed in a dummy dense rhs member.

The rhs member can be a matrix or a vector.

1-based index arrays:
---------------------

MUMPS uses exclusively FORTRAN routines and by consequence **all** array indices start with index **1** (not 0).

Default 32 bit integers compilation:
------------------------------------

By default, MUMPS is compiled in 32 bit integers **unless** it is compiled with the option -DINTSIZE64. 32 and 64 bit
versions are **not** compatible.

Lib creation:
-------------

The :file:`libmpiseq.so` file is *missing* by default in lib and must be added by hand. It is compiled in directory
libseq. :file:`libmpiseq.so` is essentially a dummy file to deal with sequential code.

The order in which the library (.so) files are given to construct the MUMPS part
of CySparse **is** important... and not standard.

"""

from cysparse.sparse.ll_mat_matrices.ll_mat_INT32_t_COMPLEX128_t cimport LLSparseMatrix_INT32_t_COMPLEX128_t
from cysparse.sparse.csc_mat_matrices.csc_mat_INT32_t_COMPLEX128_t cimport CSCSparseMatrix_INT32_t_COMPLEX128_t

from cysparse.types.cysparse_numpy_types import are_mixed_types_compatible, cysparse_to_numpy_type
from cysparse.types.cysparse_types import *

from mumps.src.mumps_INT32_COMPLEX128 cimport BaseMUMPSContext_INT32_COMPLEX128, c_to_fortran_index_array, MUMPS_INT
 
from mumps.src.mumps_INT32_COMPLEX128 cimport ZMUMPS_COMPLEX


from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython cimport Py_INCREF, Py_DECREF

from libc.stdint cimport int64_t
from libc.string cimport strncpy

import numpy as np
cimport numpy as cnp

cnp.import_array()

import time

cpdef MUMPSContext_INT32_t_COMPLEX128_t(LLSparseMatrix_INT32_t_COMPLEX128_t A, comm_fortran=-987654, verbose=False):
    """
    MUMPS Context.

    This version **only** deals with ``LLSparseMatrix_INT32_t_COMPLEX128_t`` objects.

    We follow the common use of MUMPS. In particular, we use the same names for the methods of this
    class as their corresponding counter-parts in MUMPS.

    Args:
        A: A :class:`LLSparseMatrix_INT32_t_COMPLEX128_t` object.

    Warning:
        The solver takes a "snapshot" of the matrix ``A``, i.e. the results given by the solver are only
        valid for the matrix given. If the matrix ``A`` changes aferwards, the results given by the solver won't
        reflect this change.

    """
    assert A.ncol == A.nrow

    Py_INCREF(A)  # increase ref to object to avoid the user deleting it explicitly or implicitly

    n = A.nrow
    nnz = A.nnz
    sym = A.is_symmetric

    # create i, j, val
    arow = <MUMPS_INT *> PyMem_Malloc(nnz * sizeof(MUMPS_INT))
    acol = <MUMPS_INT *> PyMem_Malloc(nnz * sizeof(MUMPS_INT))
 
 
    a_val = <COMPLEX128_t *> PyMem_Malloc(nnz * sizeof(COMPLEX128_t))
    A.take_triplet_pointers(arow, acol, a_val)
    aval = <ZMUMPS_COMPLEX *> a_val


    context = BaseMUMPSContext_INT32_COMPLEX128(n, nnz, comm_fortran, sym, verbose)
    context.get_data_pointers(arow, acol, aval)

    return context