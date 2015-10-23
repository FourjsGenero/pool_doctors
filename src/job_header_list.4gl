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
import fgl job_header_grid

schema pool_doctors

type job_header_type record like job_header.*
define m_job_header_arr dynamic array of job_header_type -- used to display multiple rows
define m_arr dynamic array of record
    major string,
    minor string,
    img string
end record

define w ui.window
define f ui.form

define m_toggle  string
define m_filter  string
define m_orderby string



private function exception()
    whenever any error call serious_error
end function



---- Control ----
function list()

    let m_toggle = nvl(m_toggle, "job_code")
    
    open window job_header_list with form "job_header_list"
    let w= ui.Window.getCurrent()
    let f = w.getform()
    call f.loadToolBar("pool_doctors_list")
    
    call db_populate() 
    call ui_populate()
    call ui_list()
    
    close window job_header_list
end function




---- User Interface ----
private function ui_populate()
define i integer

    call m_arr.clear()
    for i = 1 to m_job_header_arr.getLength()
        call ui_populate_row(i)
    end for
end function



private function ui_populate_row(l_row)
define l_row integer

    case m_toggle
        when "job_code"                     
            let m_arr[l_row].major = sfmt("%1 (%2)",lib_customer.lookup_cm_name(m_job_header_arr[l_row].jh_customer) ,m_job_header_arr[l_row].jh_customer clipped)
            let m_arr[l_row].minor = "Job:",m_job_header_arr[l_row].jh_code
            let m_arr[l_row].img = status2image(m_job_header_arr[l_row].jh_status)
        when "job_created"
            let m_arr[l_row].major = sfmt("%1 (%2)",lib_customer.lookup_cm_name(m_job_header_arr[l_row].jh_customer) ,m_job_header_arr[l_row].jh_customer clipped)
            let m_arr[l_row].minor = sfmt("Job Created: %1 %2",date(m_job_header_arr[l_row].jh_date_created), time( m_job_header_arr[l_row].jh_date_created))
            let m_arr[l_row].img = status2image(m_job_header_arr[l_row].jh_status)
    end case
end function



private function ui_list()
define l_ok boolean
define l_err_text string
define l_popup_value_select boolean

    display array m_arr to scr.* attributes(unbuffered,accept=false, cancel=true, doubleclick=select, accessorytype=disclosureindicator)

        before display
            if m_arr.getlength() = 0 then
                call show_message("No jobs loaded.  Return to front screen and sync data", true)
            end if
            
        on action select 
            call job_header_grid.view_job(m_job_header_arr[arr_curr()].jh_code)  
                returning l_ok, l_err_text

            -- repopulate upon return
            if l_ok then
                call db_populate() 
                call ui_populate()
            else
                call show_error(l_err_text, TRUE)
            end if
            

        on action toggle
            let l_popup_value_select = true
            menu "Display Detail" attributes(style="popup")
                on action job_code attributes(text="Job Code")
                    let m_toggle = "job_code"
                on action job_created attributes(text="Job Created")
                    let m_toggle = "job_created"
                on action cancel
                    let l_popup_value_select = false
            end menu
            if l_popup_value_select then
                call ui_populate()
            end if
            
        on action filter
            let l_popup_value_select = true
            menu "Filter" attributes(style="popup")
                on action all attributes(text="All")
                    initialize m_filter to null
                on action new attributes(text="New")
                    let m_filter = "jh_status = 'O'"
                on action inprogress attributes(text="In-Progress")
                    let m_filter = "jh_status = 'I'"
                on action new_inprogress attributes(text="New and in-progress")
                    let m_filter = "jh_status != 'X'"
                on action complete attributes(text="Complete")
                    let m_filter = "jh_status = 'X'"
                on action cancel
                    let l_popup_value_select = false
            end menu

            if l_popup_value_select then
                call db_populate() 
                call ui_populate()
            end if
            
        on action order
            let l_popup_value_select = true
            menu "Order" attributes(style="popup")
                on action job_number attributes(text="Job Number")
                    let m_orderby = "jh_code"
                on action date_created attributes(text="Newest to Oldest")
                    let m_orderby = "jh_date_created desc"
                on action cancel
                    let l_popup_value_select = false
            end menu

            if l_popup_value_select then
                call db_populate() 
                call ui_populate()
            end if

    end display
    if int_flag then
        let int_flag = 0
    end if
end function




private function status2image(s)
define s char(1)

    -- Map job status to an image
    case 
        when s="O" and frontend() = "GMI" return "clock-1"
        when s="I" and frontend() = "GMI" return "clock-2"
        when s="X" and frontend() = "GMI" return "clock-3"

        when s="O" and frontend() = "GMA" return "clock-1"
        when s="I" and frontend() = "GMA" return "clock-2"
        when s="X" and frontend() = "GMA" return "clock-3"
        otherwise
            return null
    end case
end function



---- Database ----
private function db_populate()
define l_sql string
define l_rec job_header_type

    
    call m_job_header_arr.clear()
    let l_sql = "select * from job_header"
    if m_filter.getlength() > 0 then
        let l_sql = l_sql, " where ", m_filter
    end if
    if m_orderby.getlength() > 0 then
        let l_sql = l_sql, " order by ", m_orderby
    end if
    declare job_header_list_curs cursor from l_sql
    foreach job_header_list_curs into l_rec.*
        let m_job_header_arr[m_job_header_arr.getlength()+1].* = l_rec.*
    end foreach
end function