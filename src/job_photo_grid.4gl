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

import fgl lib_job_photo

schema pool_doctors

type job_photo_type record like job_photo.*

public define m_job_photo_rec job_photo_type  -- used to edit a single row

define m_mode string
define m_jh_code like job_header.jh_code

define w ui.window
define f ui.form



private function exception()
    whenever any error call serious_error
end function



function add(l_jh_code)
define l_jh_code like job_header.jh_code
define l_ok boolean
define l_error_text string

    let m_jh_code = l_jh_code
    call record_default() returning l_ok, l_error_text
    if l_ok then
        -- take photo on way into screen
        try
            call ui.interface.frontcall("mobile","takePhoto",[], m_job_photo_rec.jp_photo)
        catch
            let l_error_text = "An error occured taking the photo"
        end try
        let l_ok = m_job_photo_rec.jp_photo is not null
    end if
    if l_ok then
        let m_mode = "add"
        call open_window()
        call ui_edit() returning l_ok
        if l_ok then
            call db_insert() returning l_ok, l_error_text
            if not l_ok then
                call show_error(sfmt("Unable to add row\n%1", l_error_text), true)
            end if
        end if
        call close_window()
    end if
    return l_ok, l_error_text
end function



function update(l_jp_code, l_jp_idx)
define l_jp_code like job_photo.jp_code
define l_jp_idx like job_photo.jp_idx
define l_ok boolean
define l_error_text string

    let m_job_photo_rec.jp_code = l_jp_code
    let m_job_photo_rec.jp_idx = l_jp_idx
    call db_select() returning l_ok, l_error_text
    if l_ok then
        let m_mode = "update"
        call open_window()
        call ui_edit() returning l_ok
        if l_ok then
            call db_update() returning l_ok, l_error_text
            if not l_ok then
                call show_error(sfmt("Unable to update row\n%1", l_error_text), true)
            end if
        end if
        call close_window()
    end if
    return l_ok, l_error_text
end function



function view(l_jp_code, l_jp_idx)
define l_jp_code like job_photo.jp_code
define l_jp_idx like job_photo.jp_idx

define l_ok boolean
define l_error_text string

    let m_job_photo_rec.jp_code = l_jp_code
    let m_job_photo_rec.jp_idx = l_jp_idx
    call db_select() returning l_ok, l_error_text
    if l_ok then
        call open_window()
        call ui_view()
        call close_window()
    end if
    return l_ok, l_error_text
end function



function delete(l_jp_code, l_jp_idx)
define l_jp_code like job_photo.jp_code
define l_jp_idx like job_photo.jp_idx

define l_ok boolean
define l_error_text string

define l_warning boolean
define l_warning_text string

    let m_job_photo_rec.jp_code = l_jp_code
    let m_job_photo_rec.jp_idx = l_jp_idx
    call db_select() returning l_ok, l_error_text
    if l_ok then
        call record_delete_warning() returning l_warning, l_warning_text
        if l_warning then
            call open_window()
            call ui_display()
            call ui.interface.refresh()
            let l_ok = confirm_dialog(sfmt("%1\nAre you sure you want to delete?",l_warning_text))
            call close_window()
            if not l_ok then
                let l_error_text = "Delete cancelled"
            end if
        end if
    end if
    if l_ok then
        call db_delete() returning l_ok, l_error_text
        if not l_ok then
            call show_error(sfmt("Unable to delete row\n%1", l_error_text), true)
        end if
    end if
    return l_ok, l_error_text
end function




private function open_window()
    open window job_photo_grid with form "job_photo_grid"
    let w= ui.window.getcurrent()
    let f= w.getform()
end function



private function close_window()
    close window job_photo_grid
end function



private function ui_edit()
define l_ok, l_error_text string

    input by name m_job_photo_rec.* attributes(unbuffered, without defaults=true)
        before input
            call dialog.setfieldactive("jp_code", m_mode = "add")
            call dialog.setfieldactive("jp_idx", m_mode = "add")
           
        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call show_error(l_error_text, false) \
                                        next field p1 \
                                    end if 
        after_field(jp_code)
        after_field(jp_idx)
        after_field(jp_photo)
        after_field(jp_text)
        after_field(jp_when)
        after_field(jp_lat)
        after_field(jp_lon)
       
        &undef after_field

        on action cancel
            if dialog.getfieldtouched("*") or m_mode = "add" then
                if not confirm_cancel_dialog() then
                    let int_flag = 0
                    continue input
                end if
            end if
            exit input

        after input
            -- test values
            &define field_valid(p1) call p1 ## _valid() returning l_ok, l_error_text \
            if not l_ok then \
                call show_error(l_error_text, false) \
                next field p1 \
            end if

            -- test key
            if m_mode = "add" then
                field_valid(jp_code)
                field_valid(jp_idx)
                call record_key_valid() returning l_ok, l_error_text
                if not l_ok then
                    call show_error(l_error_text, false)
                    next field current
                end if
            end if

            field_valid(jp_photo)
            field_valid(jp_text)
            field_valid(jp_when)
            field_valid(jp_lat)
            field_valid(jp_lon)

            &undef field_valid
            
            -- test record
            call record_valid() returning l_ok, l_error_text
            if not l_ok then
                call show_error(l_error_text, false)
                next field current
            end if
    end input
    if int_flag then
        let int_flag = 0
        return false
    end if
    return true
end function



private function ui_view()

    call ui_display()
    menu ""
        on action cancel
            exit menu
    end menu
end function



private function ui_display()

    display by name m_job_photo_rec.*
end function




private function record_delete_warning()

    return false, ""
end function



private function record_valid()

    -- validation involving two or more fields
    return true, ""
end function



private function record_key_valid()

    -- when adding, test that primary key value is unique
    if lib_job_photo.exists(m_job_photo_rec.jp_code, m_job_photo_rec.jp_idx) then
        return false, "Record already exists"
    end if
    return true, ""
end function



private function record_default()
define result string

    let m_job_photo_rec.jp_code = jp_code_default()
    let m_job_photo_rec.jp_idx = jp_idx_default()
    
    call ui.interface.frontcall("mobile","getgeolocation",[],[result, m_job_photo_rec.jp_lat, m_job_photo_rec.jp_lon])
       
    let m_job_photo_rec.jp_photo = jp_photo_default()
    initialize m_job_photo_rec.jp_photo_data to null
    let m_job_photo_rec.jp_text = jp_text_default()
    let m_job_photo_rec.jp_when = jp_when_default()
    return true, ""
end function



private function jp_code_default()
define l_default like job_photo.jp_code

    let l_default = m_jh_code
    return l_default
end function



private function jp_code_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_photo_rec.jp_code is null then
        return false, "Job Code must be entered"
    end if
    return l_ok, l_error_text
end function



private function jp_idx_default()
define l_default like job_photo.jp_idx

    -- maxmimum line number + 1
    let l_default = nvl(lib_job_photo.jp_idx_max(m_job_photo_rec.jp_code),0) + 1
    return l_default
end function



private function jp_idx_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_photo_rec.jp_idx is null then
        return false, "Job Photo Index must be entered"
    end if
    if m_job_photo_rec.jp_idx < 1 then
        return false, "Job Photo Index must be greater than 0"
    end if
    return l_ok, l_error_text
end function



private function jp_photo_default()
define l_default like job_photo.jp_photo

    return l_default
end function



private function jp_photo_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    return l_ok, l_error_text
end function



private function jp_text_default()
define l_default like job_photo.jp_text

    return l_default
end function



private function jp_text_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    return l_ok, l_error_text
end function



private function jp_lat_default()
define l_default like job_photo.jp_lat

    -- set by geoLocation frontcall
    return l_default
end function



private function jp_lat_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_photo_rec.jp_lat < -90
    or m_job_photo_rec.jp_lat > 90 then
        return false, "Latitude must be valid"
    end if
    
    return l_ok, l_error_text
end function



private function jp_lon_default()
define l_default like job_photo.jp_lon

    -- set by geoLocation frontcall
    return l_default
end function



private function jp_lon_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    let l_ok = true
    if m_job_photo_rec.jp_lon < -180
    or m_job_photo_rec.jp_lon > 180 then
        return false, "Longitude must be valid"
    end if
    return l_ok, l_error_text
end function



private function jp_when_default()
define l_default like job_photo.jp_when

    let l_default = current year to second
    return l_default
end function



private function jp_when_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_photo_rec.jp_when > current then
        return false, "When must be in the past"
    end if
    return l_ok, l_error_text
end function



private function db_select()

    locate m_job_photo_rec.jp_photo_data in file
    try
        select * 
        into m_job_photo_rec.*
        from job_photo 
        where job_photo.jp_code = m_job_photo_rec.jp_code
        and   job_photo.jp_idx = m_job_photo_rec.jp_idx
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_insert()

    call fgl_getfile(m_job_photo_rec.jp_photo,"photo.tmp")
    locate m_job_photo_rec.jp_photo_data in file "photo.tmp"

    try
        insert into job_photo values(m_job_photo_rec.*)
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_update()

    try
        update job_photo
        set job_photo.* = m_job_photo_rec.*
        where job_photo.jp_code = m_job_photo_rec.jp_code
        and   job_photo.jp_idx = m_job_photo_rec.jp_idx   
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_delete()

    try
        delete 
        from job_photo 
        where job_photo.jp_code = m_job_photo_rec.jp_code
        and   job_photo.jp_idx = m_job_photo_rec.jp_idx
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function
