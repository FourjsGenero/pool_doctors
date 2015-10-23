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

import fgl product_list

import fgl lib_product
import fgl lib_job_detail

schema pool_doctors

type job_detail_type record like job_detail.*

public define m_job_detail_rec job_detail_type  -- used to edit a single row

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



function update(l_jd_code, l_jd_line)
define l_jd_code like job_detail.jd_code
define l_jd_line like job_detail.jd_line

define l_ok boolean
define l_error_text string

    let m_job_detail_rec.jd_code = l_jd_code
    let m_job_detail_rec.jd_line = l_jd_line
    call db_select() returning l_ok, l_error_text
    if l_ok then
        let m_mode = "update"
        call open_window()
        call ui_edit() returning l_ok
        if l_ok then
            call db_update() returning l_ok, l_error_text
            if not l_ok then
                call show_error(sfmt("Unable to update row\n%1", l_error_text),true)
            end if
        end if
        call close_window()
    end if
    return l_ok, l_error_text
end function



function view(l_jd_code, l_jd_line)
define l_jd_code like job_detail.jd_code
define l_jd_line like job_detail.jd_line

define l_ok boolean
define l_error_text string

    let m_job_detail_rec.jd_code = l_jd_code
    let m_job_detail_rec.jd_line = l_jd_line
    call db_select() returning l_ok, l_error_text
    if l_ok then
        call open_window()
        call ui_view()
        call close_window()
    end if
    return l_ok, l_error_text
end function



function delete(l_jd_code, l_jd_line)
define l_jd_code like job_detail.jd_code
define l_jd_line like job_detail.jd_line

define l_ok boolean
define l_error_text string

define l_warning boolean
define l_warning_text string

    let m_job_detail_rec.jd_code = l_jd_code
    let m_job_detail_rec.jd_line = l_jd_line
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
                let l_error_text = "Delete Cancelled"
            end if
        end if
    end if
    if l_ok then
        call db_delete() returning l_ok, l_error_text
        if not l_ok then
            call show_error(sfmt("Unable to delete row\n%1", l_error_text),true)
        end if
    end if
    return l_ok, l_error_text
end function




private function open_window()
    open window job_detail_grid with form "job_detail_grid"
    let w= ui.window.getcurrent()
    let f= w.getform()
    call combo_populate_jd_status(ui.combobox.forname("formonly.jd_status"))
end function



private function close_window()
    close window job_detail_grid
end function



private function ui_edit()
define l_ok, l_error_text string

    input by name m_job_detail_rec.jd_code, m_job_detail_rec.jd_line, m_job_detail_rec.jd_product, m_job_detail_rec.jd_qty, m_job_detail_rec.jd_status  attributes(unbuffered, without defaults=true)
        before input
            call dialog.setFieldActive("jd_code", m_mode = "add")
            call dialog.setFieldActive("jd_line", m_mode = "add")

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call show_error(l_error_text,false) \
                                        next field p1 \
                                    end if 
                                    
        after_field(jd_code)
        after_field(jd_line)
        after_field(jd_product)
        after_field(jd_qty)
        after_field(jd_status)
        &undef after_field

    
        on action zoom infield jd_product
            let m_job_detail_rec.jd_product = nvl(product_list.select(), m_job_detail_rec.jd_product) 
            call dialog.setFieldTouched("jd_product", true)

        on action barcode 
            call do_barcode_read()
            call dialog.setFieldTouched("jd_product", true)

        on action cancel
            if dialog.getfieldtouched("*") then
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

            -- test key fields
            if m_mode = "add" then
                field_valid(jd_code)
                field_valid(jd_line)
                call record_key_valid() returning l_ok, l_error_text
                if not l_ok then
                    call show_error(l_error_text, false)
                    next field current
                end if
            end if

            -- test data fields
            field_valid(jd_product)
            field_valid(jd_qty)
            field_valid(jd_status)

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

    display by name m_job_detail_rec.jd_code, m_job_detail_rec.jd_line, m_job_detail_rec.jd_product, m_job_detail_rec.jd_qty, m_job_detail_rec.jd_status
end function



function combo_populate_jd_status(l_cb)
define l_cb ui.combobox

    call l_cb.clear()
    call l_cb.additem("0", "Entered")
    call l_cb.additem("1", "Delivered")
    call l_cb.additem("2", "Invoiced")
end function



private function do_barcode_read()
define l_pr_barcode like product.pr_barcode
define l_pr_code like product.pr_code
define l_pr_desc like product.pr_desc
define l_barcode_type string
    
    call ui.interface.frontcall("mobile","scanBarCode",[],[l_pr_barcode, l_barcode_type])
    if l_pr_barcode is not null then
        let l_pr_code = lib_product.find_from_barcode(l_pr_barcode)
        if l_pr_code is not null then
            let l_pr_desc = lib_product.lookup_pr_desc(l_pr_code)
            call show_message(sfmt("Barcode read is %1\nproduct is %2(%3)",l_pr_barcode, l_pr_code, l_pr_desc),true)
            let m_job_detail_rec.jd_product = l_pr_code
        else
            call show_error("Barcode is not in database",true)
        end if
    end if
end function



private function record_delete_warning()
    -- Sample delete warning, don't delete line if has certain status
    if m_job_detail_rec.jd_status = "0" then
        #ok to delete
    else
        return true, "Job Line has status 1" 
    end if
    return false, ""
end function



private function record_valid()

    -- validation involving two or more fields
    return true, ""
end function



private function record_key_valid()

    -- when adding, test that primary key value is unique
    if lib_job_detail.exists(m_job_detail_rec.jd_code, m_job_detail_rec.jd_line) then
        return false, "Record already exists"
    end if
    return true, ""
end function



private function record_default()
    let m_job_detail_rec.jd_code = jd_code_default()
    let m_job_detail_rec.jd_line = jd_line_default()
    let m_job_detail_rec.jd_product = jd_product_default()
    let m_job_detail_rec.jd_qty = jd_qty_default()
    let m_job_detail_rec.jd_status = jd_status_default()
    return true, ""
end function



private function jd_code_default()
define l_default like job_detail.jd_code
    let l_default = m_jh_code
    return l_default
end function



private function jd_code_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_detail_rec.jd_code is null then
        return false, "Job Code must be entered"
    end if
    return l_ok, l_error_text
end function



private function jd_line_default()
define l_default like job_detail.jd_line

    -- maxmimum line number + 1
    let l_default = nvl(lib_job_detail.jd_line_max(m_job_detail_rec.jd_code),0) + 1
    return l_default
end function



private function jd_line_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_detail_rec.jd_line is null then
        return false, "Job Line must be entered"
    end if
    if m_job_detail_rec.jd_line < 1 then
        return false, "Job Line must be greater than 0"
    end if
    return l_ok, l_error_text
end function




private function jd_product_default()
define l_default like job_detail.jd_product

    return l_default
end function



private function jd_product_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_detail_rec.jd_product is null then
        return false, "Product must be entered"
    end if
    if not lib_product.exists(m_job_detail_rec.jd_product) then
        return false, "Product must be valid"
    end if
    return l_ok, l_error_text
end function



private function jd_qty_default()
define l_default like job_detail.jd_qty

    let l_default = 1
    return l_default
end function



private function jd_qty_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_detail_rec.jd_qty is null then
        return false, "Quantity must be entered"
    end if
    if m_job_detail_rec.jd_qty < 0 then
        return false, "Quantity must be greater than 0"
    end if
    return l_ok, l_error_text
end function



private function jd_status_default()
define l_default like job_detail.jd_status
    
    let l_default = 0
    return l_default
end function



private function jd_status_valid()
define l_ok boolean
define l_error_text string

    let l_ok = true
    if m_job_detail_rec.jd_status is null then
        return false, "Status must be entered"
    end if
    if m_job_detail_rec.jd_status matches "[012]" then
        #ok
    else
        return false, "Status must be valid"
    end if
    return l_ok, l_error_text
end function



private function db_select()
    try
        select * 
        into m_job_detail_rec.*
        from job_detail 
        where job_detail.jd_code = m_job_detail_rec.jd_code
        and   job_detail.jd_line = m_job_detail_rec.jd_line
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_insert()

    try
        insert into job_detail values(m_job_detail_rec.*)
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_update()

    try
        update job_detail
        set job_detail.* = m_job_detail_rec.*
        where job_detail.jd_code = m_job_detail_rec.jd_code
           and   job_detail.jd_line = m_job_detail_rec.jd_line   
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function



private function db_delete()

    try
        delete 
        from job_detail 
        where job_detail.jd_code = m_job_detail_rec.jd_code
        and   job_detail.jd_line = m_job_detail_rec.jd_line 
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function