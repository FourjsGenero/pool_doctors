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

import fgl lib_job_header
import fgl lib_product

import fgl job_note_grid 

schema pool_doctors

type job_note_type record like job_note.*
define m_job_note_arr dynamic array of job_note_type 

define m_jh_code like job_header.jh_code

define w ui.window
define f ui.form

define m_arr dynamic array of record
    major string,
    minor string,
    img string
end record

define m_filter string



private function exception()
    whenever any error call serious_error
end function



function maintain()
define l_ok boolean
define l_err_text string

    open window job_note_list with form "job_note_list"
    let w= ui.window.getcurrent()
    let f = w.getform()
    call f.loadtoolbar("pool_doctors_list")
    
    call db_populate() returning l_ok, l_err_text
    if l_ok then
        call ui_populate()
        call ui_list()
    else
        call show_error(l_err_text, true)
    end if
    
    close window job_note_list
end function


function maintain_job(l_jn_code)
define l_jn_code like job_note.jn_code

    let m_jh_code = l_jn_code
    let m_filter = sfmt("job_note.jn_code = '%1'", l_jn_code clipped)
    call maintain()
end function




private function ui_populate()
define i integer

    call m_arr.clear()
    for i = 1 to m_job_note_arr.getLength()
        call ui_populate_row(i)
    end for
end function



private function ui_populate_row(l_row)
define l_row integer

    let m_arr[l_row].major = m_job_note_arr[l_row].jn_note clipped
    let m_arr[l_row].minor = ""
    let m_arr[l_row].img = ""
end function



private function ui_list()
define l_ok boolean
define l_error_text string

define l_row integer
define l_editable boolean

    display array m_arr to scr.* attributes(unbuffered, accept=false, cancel=true, doubleclick=update, accessorytype=disclosureindicator)

        before display
            let l_editable = lib_job_header.editable(m_jh_code)
            call dialog.setActionActive("append",l_editable)
            call dialog.setActionActive("delete",l_editable)
            if l_editable and m_arr.getLength() = 0 then
                call show_message("Tap + to add", false)
            end if
            
        before row
            let l_row = dialog.getcurrentrow("scr")
            
        on append  
            call job_note_grid.add(m_jh_code)
                returning l_ok, l_error_text
            if not l_ok then
                call show_error(l_error_text, true)
                let int_flag = true
            else
                let m_job_note_arr[m_job_note_arr.getlength()+1].* = job_note_grid.m_job_note_rec.*
                call ui_populate_row(m_job_note_arr.getlength())
            end if
            
        on update 
            if lib_job_header.editable(m_job_note_arr[l_row].jn_code) then
                call job_note_grid.update(m_job_note_arr[l_row].jn_code, m_job_note_arr[l_row].jn_idx)
                    returning l_ok, l_error_text
                if not l_ok then
                    call show_error(l_error_text, true)
                    let int_flag = true
                end if
                let m_job_note_arr[l_row].* = job_note_grid.m_job_note_rec.*
                call ui_populate_row(l_row)
            else
                -- if we cant update, view it instead
                call job_note_grid.view(m_job_note_arr[l_row].jn_code, m_job_note_arr[l_row].jn_idx)
                   returning l_ok, l_error_text
            end if
           
        on delete 
            call job_note_grid.delete(m_job_note_arr[l_row].jn_code, m_job_note_arr[l_row].jn_idx)
                returning l_ok, l_error_text
            if not l_ok then
                call show_error(l_error_text, true)
                let int_flag = true
            end if
            call m_job_note_arr.deleteElement(l_row)

    end display
    if int_flag then
        let int_flag = 0
    end if
end function
 


private function db_populate()
define l_sql string
define l_rec job_note_type

    try
        call m_job_note_arr.clear()
        let l_sql = "select * from job_note"
        if m_filter.getLength() > 0 then
            let l_sql = l_sql, " where ", m_filter
        end if

        declare job_note_list_curs cursor from l_sql
        foreach job_note_list_curs into l_rec.*
            let m_job_note_arr[m_job_note_arr.getLength()+1].* = l_rec.*
        end foreach
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



-- there is a bug in dependency diagram which doesn't show links well if the 
-- called function has the same name in two different import fgl modules
-- workaround by adding a functon with a unique name
-- this function can be removed when bug GST-12511 fixed
function job_note_list()
    # do nothing,  never executed
end function