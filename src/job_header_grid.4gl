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

import fgl lib_customer
import fgl lib_job_detail
import fgl lib_job_note
import fgl lib_job_photo
import fgl lib_job_timesheet

import fgl customer_grid
import fgl job_header_complete
import fgl job_detail_list
import fgl job_photo_list
import fgl job_note_list
import fgl job_timesheet_list

schema pool_doctors

type job_header_type record like job_header.*

define m_job_header_rec job_header_type  

define w ui.window
define f ui.form



private function exception()
    whenever any error call serious_error
end function



---- Control ----
function view_job(l_jh_code)
define l_jh_code like job_header.jh_code

define l_ok boolean
define l_err_text string

    let m_job_header_rec.jh_code = l_jh_code
    call db_select() returning l_ok, l_err_text
    if l_ok then
        open window job_header_grid with form "job_header_grid"
        let w= ui.Window.getCurrent()
        let f= w.getForm()
        call ui_view()
        close window job_header_grid
    else
        call show_error("Job Record not found", TRUE)
    end if
    return l_ok, l_err_text
end function



---- User Interface ----
private function ui_view()
define l_ok boolean
define l_err_text string


define n om.DomNode


    --let n = f.findNode("Button","lines")
    --call n.setAttribute("text",SFMT(" %1 Parts",lib_job_detail.count(m_job_header_rec.jh_code)))
--
    --let n = f.findNode("Button","photo")
    --call n.setAttribute("text",SFMT(" %1 Photos",lib_job_photo.count(m_job_header_rec.jh_code)))
--
    --let n = f.findNode("Button","notes")
    --call n.setAttribute("text",SFMT(" %1 Notes",lib_job_note.count(m_job_header_rec.jh_code)))
--
    --let n = f.findNode("Button","time")
    --call n.setAttribute("text",SFMT(" %1 Timesheet Lines",lib_job_timesheet.count(m_job_header_rec.jh_code)))

   display by name m_job_header_rec.jh_code, m_job_header_rec.jh_customer, m_job_header_rec.jh_date_created

   display sfmt("%1 Parts", lib_job_detail.count(m_job_header_rec.jh_code)) to lines_count
   display sfmt("%1 Notes", lib_job_note.count(m_job_header_rec.jh_code)) to notes_count
   display sfmt("%1 Photos", lib_job_photo.count(m_job_header_rec.jh_code)) to photos_count
   display sfmt("%1 Timesheet Lines", lib_job_timesheet.count(m_job_header_rec.jh_code)) to timesheet_count

    display sfmt("%1 (%2)",lib_customer.lookup_cm_name(m_job_header_rec.jh_customer) ,m_job_header_rec.jh_customer clipped) to jh_customer
    
    menu ""
        before menu
            call state(dialog)

        on action cancel
            exit menu

        on action customer  
            call customer_grid.view_customer(m_job_header_rec.jh_customer) returning l_ok, l_err_text

        on action lines 
            if m_job_header_rec.jh_status matches "[IX]" then
                call job_detail_list.maintain_job(m_job_header_rec.jh_code)
                display sfmt("%1 Parts", lib_job_detail.count(m_job_header_rec.jh_code)) to lines_count
            else
                call show_message("Tap Start before entering job data", true)
            end if
            
        on action photo  
             if m_job_header_rec.jh_status matches "[IX]" then
                call job_photo_list.maintain_job(m_job_header_rec.jh_code)
                display sfmt("%1 Photos", lib_job_photo.count(m_job_header_rec.jh_code)) to photos_count
            else
                call show_message("Tap Start before entering job data", true)
            end if

        on action notes  
             if m_job_header_rec.jh_status matches "[IX]" then
                call job_note_list.maintain_job(m_job_header_rec.jh_code)
                display sfmt("%1 Notes", lib_job_note.count(m_job_header_rec.jh_code)) to notes_count
             else
                call show_message("Tap Start before entering job data", true)
            end if
            
        on action time 
             if m_job_header_rec.jh_status matches "[IX]" then
                call job_timesheet_list.maintain_job(m_job_header_rec.jh_code)
                display sfmt("%1 Timesheet Lines", lib_job_timesheet.count(m_job_header_rec.jh_code)) to timesheet_count
            else
                call show_message("Tap Start before entering job data", true)
            end if

        on action start  
            call db_update_start() returning l_ok, l_err_text
            if not l_ok then
                call show_error(sfmt("Error starting job %1", l_err_text), true)
            end if
            call state(dialog)
            
        on action complete  
            call job_header_complete.complete(m_job_header_rec.jh_code) returning 
               l_ok, l_err_text
            if not l_ok then
                continue menu
            end if
            call db_select() returning l_ok, l_err_text
            if not l_ok then
                -- shouldn't occur
            end if
            call state(dialog)
            
    end menu
end function



private function state(d)
define d ui.dialog 

    call d.setActionActive("start", m_job_header_rec.jh_status = "O")
    call d.setActionActive("complete", m_job_header_rec.jh_status = "I")
end function



---- Database ----
private function db_select()
    try
        select * 
        into m_job_header_rec.*
        from job_header 
        where 
            job_header.jh_code = m_job_header_rec.jh_code
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_update_start()
    let m_job_header_rec.jh_status = "I"
    try
        update job_header
        set 
            jh_status = m_job_header_rec.jh_status
        where 
            job_header.jh_code = m_job_header_rec.jh_code
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function




-- there is a bug in dependency diagram which doesn't show links well if the 
-- called function has the same name in two different import fgl modules
-- workaround by adding a functon with a unique name
-- this function gets arund that by adding unused calls with unique names
-- this function can be removed when bug GST-12511 fixed
private function bug_fix_12511()
    call job_detail_list.job_detail_list()
    call job_note_list.job_note_list()
    call job_photo_list.job_photo_list()
    call job_timesheet_list.job_timesheet_list()
end function