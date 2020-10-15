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
FUNCTION count(l_jd_code)
    DEFINE l_jd_code LIKE job_detail.jd_code

    DEFINE l_count INTEGER

    DEFINE l_sql STRING

    LET l_sql = "select count(*) from job_detail where jd_code = ? "

    DECLARE job_detail_count_curs CURSOR FROM l_sql
    OPEN job_detail_count_curs USING l_jd_code
    FETCH job_detail_count_curs INTO l_count

    RETURN l_count
END FUNCTION

-- For a given job code, return the maximum job detail line number
FUNCTION jd_line_max(l_jd_code)
    DEFINE l_jd_code LIKE job_detail.jd_code

    DEFINE l_jd_line LIKE job_detail.jd_line

    SELECT MAX(jd_line) INTO l_jd_line FROM job_detail WHERE jd_code = l_jd_code

    RETURN l_jd_line
END FUNCTION

-- Determine if a given job detail line exists
FUNCTION exists(l_jd_code, l_jd_line)
    DEFINE l_jd_code LIKE job_detail.jd_code
    DEFINE l_jd_line LIKE job_detail.jd_line

    SELECT 'x' FROM job_detail WHERE job_detail.jd_code = l_jd_code AND job_detail.jd_line = l_jd_line

    IF status == NOTFOUND THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
