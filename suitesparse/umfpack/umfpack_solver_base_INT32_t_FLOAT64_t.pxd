from suitesparse.solver_INT32_t_FLOAT64_t cimport Solver_INT32_t_FLOAT64_t

from suitesparse.common_types.suitesparse_types cimport *

cdef extern from "umfpack.h":

    cdef enum:
        UMFPACK_CONTROL, UMFPACK_INFO


cdef class UmfpackSolverBase_INT32_t_FLOAT64_t(Solver_INT32_t_FLOAT64_t):
    cdef:

        # UMFPACK takes a C CSC matrix object
        INT32_t * ind
        INT32_t * row


        FLOAT64_t * val


        # UMFPACK opaque objects
        void * symbolic

        void * numeric

        # Control and Info arrays
        public double info[UMFPACK_INFO]
        public double control[UMFPACK_CONTROL]


    cdef check_matrix(self)