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



-- For a given job code, return the number of job photo lines
function count(l_jp_code)
define l_jp_code like job_photo.jp_code

define l_count integer

define l_sql string

    let l_sql = "select count(*) from job_photo where jp_code = ? "
    
    declare job_photo_count_curs cursor from l_sql
    open job_photo_count_curs using l_jp_code
    fetch job_photo_count_curs into l_count
    
    return l_count
end function



-- For a given job code, return the maximum job photo line number
function jp_idx_max(l_jp_code)
define l_jp_code like job_photo.jp_code

define l_jp_idx like job_photo.jp_idx

    select max(jp_idx)
    into l_jp_idx
    from job_photo
    where jp_code = l_jp_code

    return l_jp_idx
end function



-- Determine if a given job photo line exists
function exists(l_jp_code, l_jp_idx)
define l_jp_code like job_photo.jp_code
define l_jp_idx  like job_photo.jp_idx

    select 'x'
    from job_photo
    where job_photo.jp_code = l_jp_code
    and   job_photo.jp_idx = l_jp_idx 

    if status==notfound then
        return false
    end if
    return true
end function