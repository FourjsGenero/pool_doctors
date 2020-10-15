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

-- For a given job code, return the number of job detail lines
FUNCTION count(l_jn_code)
    DEFINE l_jn_code LIKE job_note.jn_code

    DEFINE l_count INTEGER

    DEFINE l_sql STRING

    LET l_sql = "select count(*) from job_note where jn_code = ? "

    DECLARE job_note_count_curs CURSOR FROM l_sql
    OPEN job_note_count_curs USING l_jn_code
    FETCH job_note_count_curs INTO l_count

    RETURN l_count
END FUNCTION

-- For a given job code, return the maximum job note line number
FUNCTION jn_idx_max(l_jn_code)
    DEFINE l_jn_code LIKE job_note.jn_code

    DEFINE l_jn_idx LIKE job_note.jn_idx

    SELECT MAX(jn_idx) INTO l_jn_idx FROM job_note WHERE jn_code = l_jn_code

    RETURN l_jn_idx
END FUNCTION

-- Determine if a given job note line exists
FUNCTION exists(l_jn_code, l_jn_idx)
    DEFINE l_jn_code LIKE job_note.jn_code
    DEFINE l_jn_idx LIKE job_note.jn_idx

    SELECT 'x' FROM job_note WHERE job_note.jn_code = l_jn_code AND job_note.jn_idx = l_jn_idx

    IF status == NOTFOUND THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
