from cysparse.types.cysparse_types cimport *

from cysparse.sparse.ll_mat_matrices.ll_mat_INT64_t_COMPLEX128_t cimport LLSparseMatrix_INT64_t_COMPLEX128_t
from cysparse.sparse.csc_mat_matrices.csc_mat_INT64_t_COMPLEX128_t cimport CSCSparseMatrix_INT64_t_COMPLEX128_t


cdef extern from "umfpack.h":
    cdef enum:
        UMFPACK_CONTROL, UMFPACK_INFO


cdef class UmfpackContext_INT64_t_COMPLEX128_t:
    cdef:
        LLSparseMatrix_INT64_t_COMPLEX128_t A

        INT64_t nrow
        INT64_t ncol
        INT64_t nnz

        # Matrix A in CSC format
        CSCSparseMatrix_INT64_t_COMPLEX128_t csc_mat

        # UMFPACK opaque objects
        void * symbolic
        bint symbolic_computed

        void * numeric
        bint numeric_computed

        # Control and Info arrays
        public double info[UMFPACK_INFO]
        public double control[UMFPACK_CONTROL]


        # we keep internally two arrays for the complex numbers: this is required by UMFPACK...
        FLOAT64_t * csc_rval
        FLOAT64_t * csc_ival

        bint internal_real_arrays_computed

    cdef create_real_arrays_if_needed(self)


    cdef int _create_symbolic(self)
    cdef int _create_numeric(self)
