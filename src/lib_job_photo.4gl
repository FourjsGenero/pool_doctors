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

-- For a given job code, return the number of job photo lines
FUNCTION count(l_jp_code)
    DEFINE l_jp_code LIKE job_photo.jp_code

    DEFINE l_count INTEGER

    DEFINE l_sql STRING

    LET l_sql = "select count(*) from job_photo where jp_code = ? "

    DECLARE job_photo_count_curs CURSOR FROM l_sql
    OPEN job_photo_count_curs USING l_jp_code
    FETCH job_photo_count_curs INTO l_count

    RETURN l_count
END FUNCTION

-- For a given job code, return the maximum job photo line number
FUNCTION jp_idx_max(l_jp_code)
    DEFINE l_jp_code LIKE job_photo.jp_code

    DEFINE l_jp_idx LIKE job_photo.jp_idx

    SELECT MAX(jp_idx) INTO l_jp_idx FROM job_photo WHERE jp_code = l_jp_code

    RETURN l_jp_idx
END FUNCTION

-- Determine if a given job photo line exists
FUNCTION exists(l_jp_code, l_jp_idx)
    DEFINE l_jp_code LIKE job_photo.jp_code
    DEFINE l_jp_idx LIKE job_photo.jp_idx

    SELECT 'x' FROM job_photo WHERE job_photo.jp_code = l_jp_code AND job_photo.jp_idx = l_jp_idx

    IF status == NOTFOUND THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
