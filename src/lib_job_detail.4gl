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

schema "pool_doctors"



private function exception()
    whenever any error call serious_error
end function



-- For a given job code, return the number of job detail lines
function count(l_jd_code)
define l_jd_code like job_detail.jd_code

define l_count integer

define l_sql string

    let l_sql = "select count(*) from job_detail where jd_code = ? "
    
    declare job_detail_count_curs cursor from l_sql
    open job_detail_count_curs using l_jd_code
    fetch job_detail_count_curs into l_count
    
    return l_count
end function



-- For a given job code, return the maximum job detail line number
function jd_line_max(l_jd_code)
define l_jd_code like job_detail.jd_code

define l_jd_line like job_detail.jd_line

    select max(jd_line)
    into l_jd_line
    from job_detail
    where jd_code = l_jd_code

    return l_jd_line
end function



-- Determine if a given job detail line exists
function exists(l_jd_code, l_jd_line)
define l_jd_code like job_detail.jd_code
define l_jd_line like job_detail.jd_line

    select 'x'
    from job_detail
    where job_detail.jd_code = l_jd_code
    and   job_detail.jd_line = l_jd_line 

    if status==notfound then
        return false
    end if
    return true
end function