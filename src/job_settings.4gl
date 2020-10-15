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

import fgl lib_settings
import fgl lib_error
import fgl lib_ui

schema pool_doctors

define m_job_settings_rec record
    js_url like job_settings.js_url,
    js_group like job_settings.js_group,
    js_map like job_settings.js_map
end record



private function exception()
    whenever any error call lib_error.serious_error
end function


---- Control ----


function edit()
define l_ok boolean
define l_err_text string

    initialize m_job_settings_rec.* to null
    call db_select() returning l_ok, l_err_text
    if l_ok then
        open window job_settings with form "job_settings"
        call ui_edit() returning l_ok
    
        if l_ok then
            call db_update()
                returning l_ok, l_err_text
            if l_ok then    
                call lib_settings.populate()
            end if
        end if
        close window job_settings
    else
        call lib_ui.show_error("Settings not found", TRUE)
    end if
    return l_ok, l_err_text    
end function



private function ui_edit()
define l_ok, l_error_text string

    let int_flag = 0 # something not setting this before i get here
    input by name m_job_settings_rec.js_url,
                  m_job_settings_rec.js_group,
                  m_job_settings_rec.js_map
                  attributes (without defaults=true, unbuffered)
    
        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call lib_ui.show_error(l_error_text,false) \
                                        next field p1 \
                                    end if 
                                    
        after_field(js_url)
        after_field(js_group)
        after_field(js_map)

        &undef after_field

        on action cancel
            if dialog.getfieldtouched("*") then
                if not lib_ui.confirm_cancel_dialog() then
                    let int_flag = 0
                    continue input
                end if
            end if
            exit input
        
        after input
            -- test values
            &define field_valid(p1) call p1 ## _valid() returning l_ok, l_error_text \
            if not l_ok then \
                call lib_ui.show_error(l_error_text, false) \
                next field p1 \
            end if

            -- test data fields
            field_valid(js_url)
            field_valid(js_group)
            field_valid(js_map)

            &undef field_valid
            
            -- test record
            call record_valid() returning l_ok, l_error_text
            if not l_ok then
                call lib_ui.show_error(l_error_text, false)
                next field current
            end if
    end input
    if int_flag then
        let int_flag = 0
        return false
    end if
    return true
end function



private function js_url_valid()

    if m_job_settings_rec.js_url is null then
        return false, "URL must be entered"
    end if
    return true, ""
end function


private function js_group_valid()

    if m_job_settings_rec.js_group is null then
        return false, "Group must be entered"
    end if
    return true, ""
end function

private function js_map_valid()

    if m_job_settings_rec.js_map is null then
        return false, "Map must be entered"
    end if
    if m_job_settings_rec.js_map >=0 and m_job_settings_rec.js_map<=2 then
        #ok
    else
        return false, "Map must be valid"
    end if
    return true, ""
end function





private function record_valid()
    return true, ""
end function



private function db_select()
    try
        select js_url, js_group, js_map
        into m_job_settings_rec.js_url, m_job_settings_rec.js_group, m_job_settings_rec.js_map
        from job_settings
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_update()
    try
        update job_settings
        set 
            js_url = m_job_settings_rec.js_url,
            js_group = m_job_settings_rec.js_group,
            js_map =  m_job_settings_rec.js_map
        where 
            1=1
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function

function combo_populate_map_settings(cb)
define cb ui.ComboBox

    call cb.clear()
    call cb.addItem(0,"None")
    call cb.addItem(1,"geo:")
    call cb.addItem(2,"https://google.com/maps")
    call cb.addItem(3,"Google Maps App (iOS only)")
end function