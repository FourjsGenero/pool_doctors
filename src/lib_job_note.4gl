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
function count(l_jn_code)
define l_jn_code like job_note.jn_code

define l_count integer

define l_sql string

    let l_sql = "select count(*) from job_note where jn_code = ? "
    
    declare job_note_count_curs cursor from l_sql
    open job_note_count_curs using l_jn_code
    fetch job_note_count_curs into l_count
    
    return l_count
end function



-- For a given job code, return the maximum job note line number
function jn_idx_max(l_jn_code)
define l_jn_code like job_note.jn_code

define l_jn_idx like job_note.jn_idx

    select max(jn_idx)
    into l_jn_idx
    from job_note
    where jn_code = l_jn_code

    return l_jn_idx
end function



-- Determine if a given job note line exists
function exists(l_jn_code, l_jn_idx)
define l_jn_code like job_note.jn_code
define l_jn_idx  like job_note.jn_idx

    select 'x'
    from job_note
    where job_note.jn_code = l_jn_code
    and   job_note.jn_idx = l_jn_idx 

    if status==notfound then
        return false
    end if
    return true
end function