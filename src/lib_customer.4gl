#
#       (c) Copyright 2014, Blue J Software - www.bluejs.com
#
#       MIT License (http://www.opensource.org/licenses/mit-license.php)
#
#       Permission is hereby granted, free of charge, to any person
#       obtaining a copy of this software and associated documentation
#       files (the "Software"), to deal in the Software without restriction,
#       including without limitation the rights to use, copy, modify, merge,
#       publish, distribute, sublicense, and/or sell copies of the Software,
#       and to permit persons to whom the Software is furnished to do so,
#       subject to the following conditions:
#
#       The above copyright notice and this permission notice shall be
#       included in all copies or substantial portions of the Software.
#
#       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#       EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#       OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#       NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
#       BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
#       ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#       CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#       THE SOFTWARE.

IMPORT FGL lib_error

SCHEMA "pool_doctors"

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

-- For a given customer, return the name
FUNCTION lookup_cm_name(l_cm_code)
    DEFINE l_cm_code LIKE customer.cm_code
    DEFINE l_cm_name LIKE customer.cm_name

    SELECT customer.cm_name INTO l_cm_name FROM customer WHERE customer.cm_code = l_cm_code

    RETURN l_cm_name
END FUNCTION

-- For a given customer, return the rep code
FUNCTION lookup_cm_rep(l_cm_code)
    DEFINE l_cm_code LIKE customer.cm_code
    DEFINE l_cm_rep LIKE customer.cm_rep

    SELECT customer.cm_rep INTO l_cm_rep FROM customer WHERE customer.cm_code = l_cm_code

    RETURN l_cm_rep
END FUNCTION
