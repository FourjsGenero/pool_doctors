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

IMPORT FGL lib_error
IMPORT FGL lib_ui

SCHEMA pool_doctors

DEFINE m_job_header_rec RECORD
    jh_code LIKE job_header.jh_code,
    jh_status LIKE job_header.jh_status,
    jh_date_signed LIKE job_header.jh_date_signed,
    jh_name_signed LIKE job_header.jh_name_signed,
    jh_signature LIKE job_header.jh_signature
END RECORD

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

FUNCTION complete(l_jh_code)
    DEFINE l_jh_code LIKE job_header.jh_code
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    INITIALIZE m_job_header_rec.* TO NULL
    LET m_job_header_rec.jh_code = l_jh_code
    OPEN WINDOW job_header_complete WITH FORM "job_header_complete"
    CALL ui_edit() RETURNING l_ok

    IF l_ok THEN
        LET m_job_header_rec.jh_status = "X"
        LET m_job_header_rec.jh_date_signed = CURRENT YEAR TO MINUTE
        CALL db_update() RETURNING l_ok, l_err_text
    END IF

    CLOSE WINDOW job_header_complete
    RETURN l_ok, l_err_text
END FUNCTION

PRIVATE FUNCTION ui_edit()
    DEFINE l_ok, l_error_text STRING

    LET int_flag = 0 # something not setting this before i get here
    INPUT BY NAME m_job_header_rec.jh_name_signed, m_job_header_rec.jh_signature ATTRIBUTES(WITHOUT DEFAULTS = TRUE, UNBUFFERED)

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call lib_ui.show_error(l_error_text,false) \
                                        next field p1 \
                                    end if

        after_field(jh_name_signed)
        after_field(jh_signature)
        &undef after_field

        ON ACTION cancel
            IF dialog.getfieldtouched("*") THEN
                IF NOT lib_ui.confirm_cancel_dialog() THEN
                    LET int_flag = 0
                    CONTINUE INPUT
                END IF
            END IF
            EXIT INPUT

        AFTER INPUT
            -- test values
            &define field_valid(p1) call p1 ## _valid() returning l_ok, l_error_text \
            if not l_ok then \
                call lib_ui.show_error(l_error_text, false) \
                next field p1 \
            end if

            -- test data fields
            field_valid(jh_name_signed)
            field_valid(jh_signature)
            &undef field_valid

            -- test record
            CALL record_valid() RETURNING l_ok, l_error_text
            IF NOT l_ok THEN
                CALL lib_ui.show_error(l_error_text, FALSE)
                NEXT FIELD CURRENT
            END IF
    END INPUT
    IF int_flag THEN
        LET int_flag = 0
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

PRIVATE FUNCTION jh_name_signed_valid()

    IF m_job_header_rec.jh_name_signed IS NULL THEN
        RETURN FALSE, "Name must be entered"
    END IF
    IF length(m_job_header_rec.jh_name_signed CLIPPED) > 2 THEN
        #ok
    ELSE
        RETURN FALSE, "Name must be more than two characters"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION jh_signature_valid()

    IF m_job_header_rec.jh_signature IS NULL THEN
        RETURN FALSE, "Signature must be entered"
    END IF
    IF length(m_job_header_rec.jh_signature CLIPPED) > 20 THEN
        #ok
    ELSE
        RETURN FALSE, "Signature too short"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_valid()
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_update()
    TRY
        UPDATE job_header
            SET jh_status = m_job_header_rec.jh_status, jh_signature = m_job_header_rec.jh_signature,
                jh_date_signed = m_job_header_rec.jh_date_signed, jh_name_signed = m_job_header_rec.jh_name_signed
            WHERE job_header.jh_code = m_job_header_rec.jh_code
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION
