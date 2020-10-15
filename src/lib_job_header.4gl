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

-- Is the given job number editable, that is jh_status = "I" for in-progress
FUNCTION editable(l_jh_code)
    DEFINE l_jh_code LIKE job_header.jh_code

    DEFINE l_jh_status LIKE job_header.jh_status

    SELECT jh_status INTO l_jh_status FROM job_header WHERE jh_code = l_jh_code

    RETURN (l_jh_status = "I")
END FUNCTION

-- Does the given job number exist
FUNCTION exists(l_jh_code)
    DEFINE l_jh_code LIKE job_header.jh_code

    SELECT 'x' FROM job_header WHERE job_header.jh_code = l_jh_code

    IF status == NOTFOUND THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
