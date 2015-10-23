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

schema pool_doctors

define m_job_header_rec record
    jh_code like job_header.jh_code,
    jh_status like job_header.jh_status,
    jh_date_signed like job_header.jh_date_signed,
    jh_name_signed like job_header.jh_name_signed,
    jh_signature like job_header.jh_signature
end record



private function exception()
    whenever any error call serious_error
end function



function complete(l_jh_code)
define l_jh_code like job_header.jh_code
define l_ok boolean
define l_err_text string

    initialize m_job_header_rec.* to null
    let m_job_header_rec.jh_code = l_jh_code
    open window job_header_complete with form "job_header_complete"
    call ui_edit() returning l_ok
    
    if l_ok then
        let m_job_header_rec.jh_status = "X"
        let m_job_header_rec.jh_date_signed = current year to minute
        call db_update()
            returning l_ok, l_err_text
    end if

    close window job_header_complete
    return l_ok, l_err_text
end function



private function ui_edit()
define l_ok, l_error_text string

    let int_flag = 0 # something not setting this before i get here
    input by name m_job_header_rec.jh_name_signed, m_job_header_rec.jh_signature attributes(without defaults=true, unbuffered)

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call show_error(l_error_text,false) \
                                        next field p1 \
                                    end if 
                                    
        after_field(jh_name_signed)
        after_field(jh_signature)
        &undef after_field

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

            -- test data fields
            field_valid(jh_name_signed)
            field_valid(jh_signature)
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



private function jh_name_signed_valid()

    if m_job_header_rec.jh_name_signed is null then
        return false, "Name must be entered"
    end if
    if length(m_job_header_rec.jh_name_signed clipped) > 2 then
        #ok
    else
        return false, "Name must be more than two characters"
    end if
    return true, ""
end function



private function jh_signature_valid()

    if m_job_header_rec.jh_signature is null then
        return false, "Signature must be entered"
    end if
    if length(m_job_header_rec.jh_signature clipped) > 20 then
        #ok
    else
        return false, "Signature too short"
    end if
    return true, ""
end function



private function record_valid()
    return true, ""
end function



private function db_update()
    try
        update job_header
        set 
            jh_status = m_job_header_rec.jh_status,
            jh_signature = m_job_header_rec.jh_signature,
            jh_date_signed = m_job_header_rec.jh_date_signed,
            jh_name_signed = m_job_header_rec.jh_name_signed
        where 
            job_header.jh_code = m_job_header_rec.jh_code
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function