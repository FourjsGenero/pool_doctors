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

IMPORT FGL lib_job_timesheet

SCHEMA pool_doctors

TYPE job_timesheet_type RECORD LIKE job_timesheet.*

PUBLIC DEFINE m_job_timesheet_rec job_timesheet_type -- used to edit a single row

DEFINE m_mode STRING
DEFINE m_jh_code LIKE job_header.jh_code

DEFINE w ui.window
DEFINE f ui.form

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

FUNCTION add(l_jh_code)
    DEFINE l_jh_code LIKE job_header.jh_code
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_jh_code = l_jh_code
    CALL record_default() RETURNING l_ok, l_error_text
    IF l_ok THEN
        LET m_mode = "add"
        CALL open_window()
        CALL ui_edit() RETURNING l_ok
        IF l_ok THEN
            CALL db_insert() RETURNING l_ok, l_error_text
            IF NOT l_ok THEN
                CALL lib_ui.show_error(SFMT("unable to add row\n%1", l_error_text), TRUE)
            END IF
        END IF
        CALL close_window()
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION update(l_jt_code, l_jt_idx)
    DEFINE l_jt_code LIKE job_timesheet.jt_code
    DEFINE l_jt_idx LIKE job_timesheet.jt_idx
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_job_timesheet_rec.jt_code = l_jt_code
    LET m_job_timesheet_rec.jt_idx = l_jt_idx
    CALL db_select() RETURNING l_ok, l_error_text
    IF l_ok THEN
        LET m_mode = "update"
        CALL open_window()
        CALL ui_edit() RETURNING l_ok
        IF l_ok THEN
            CALL db_update() RETURNING l_ok, l_error_text
            IF NOT l_ok THEN
                CALL lib_ui.show_error(SFMT("Unable to update row\n%1", l_error_text), TRUE)
            END IF
        END IF
        CALL close_window()
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION view(l_jt_code, l_jt_idx)
    DEFINE l_jt_code LIKE job_timesheet.jt_code
    DEFINE l_jt_idx LIKE job_timesheet.jt_idx

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_job_timesheet_rec.jt_code = l_jt_code
    LET m_job_timesheet_rec.jt_idx = l_jt_idx
    CALL db_select() RETURNING l_ok, l_error_text
    IF l_ok THEN
        CALL open_window()
        CALL ui_view()
        CALL close_window()
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION delete(l_jt_code, l_jt_idx)
    DEFINE l_jt_code LIKE job_timesheet.jt_code
    DEFINE l_jt_idx LIKE job_timesheet.jt_idx

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    DEFINE l_warning BOOLEAN
    DEFINE l_warning_text STRING

    LET m_job_timesheet_rec.jt_code = l_jt_code
    LET m_job_timesheet_rec.jt_idx = l_jt_idx
    CALL db_select() RETURNING l_ok, l_error_text
    IF l_ok THEN
        CALL record_delete_warning() RETURNING l_warning, l_warning_text
        IF l_warning THEN
            CALL open_window()
            CALL ui_display()
            CALL ui.interface.refresh()
            LET l_ok = lib_ui.confirm_dialog(SFMT("%1\nAre you sure you want to delete?", l_warning_text))
            CALL close_window()
            IF NOT l_ok THEN
                LET l_error_text = "Delete cancelled"
            END IF
        END IF
    END IF
    IF l_ok THEN
        CALL db_delete() RETURNING l_ok, l_error_text
        IF NOT l_ok THEN
            CALL lib_ui.show_error(SFMT("Unable to delete row\n%1", l_error_text), TRUE)
        END IF
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION open_window()
    OPEN WINDOW job_timesheet_grid WITH FORM "job_timesheet_grid"
    LET w = ui.window.getcurrent()
    LET f = w.getform()
    CALL combo_populate_jt_charge_code(ui.combobox.forname("formonly.jt_charge_code_id"))
END FUNCTION

PRIVATE FUNCTION close_window()
    CLOSE WINDOW job_timesheet_grid
END FUNCTION

PRIVATE FUNCTION ui_edit()
    DEFINE l_ok, l_error_text STRING

    INPUT BY NAME m_job_timesheet_rec.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS = TRUE)

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call lib_ui.show_error(l_error_text, false) \
                                        next field p1 \
                                    end if
        after_field(jt_code)
        after_field(jt_idx)
        after_field(jt_start)
        after_field(jt_finish)
        after_field(jt_charge_code_id)
        after_field(jt_text)

        &undef after_field

        ON ACTION cancel
            IF dialog.getFieldTouched("*") THEN
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

            -- test key
            IF m_mode = "add" THEN
                field_valid(jt_code)
                field_valid(jt_idx)
                CALL record_key_valid() RETURNING l_ok, l_error_text
                IF NOT l_ok THEN
                    CALL lib_ui.show_error(l_error_text, FALSE)
                    NEXT FIELD CURRENT
                END IF
            END IF

            field_valid(jt_start)
            field_valid(jt_finish)
            field_valid(jt_charge_code_id)
            field_valid(jt_text)

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

PRIVATE FUNCTION ui_view()

    CALL ui_display()
    MENU ""
        ON ACTION cancel
            EXIT MENU

    END MENU
END FUNCTION

PRIVATE FUNCTION ui_display()

    DISPLAY BY NAME m_job_timesheet_rec.*
END FUNCTION

PRIVATE FUNCTION combo_populate_jt_charge_code(l_cb)
    DEFINE l_cb ui.combobox

    CALL l_cb.clear()
    CALL l_cb.additem("1", "Standard")
    CALL l_cb.additem("2", "Overtime")
    CALL l_cb.additem("0", "Free")
END FUNCTION

PRIVATE FUNCTION record_delete_warning()

    RETURN FALSE, ""
END FUNCTION

PRIVATE FUNCTION record_valid()

    -- validation involving two or more fields
    IF m_job_timesheet_rec.jt_start > m_job_timesheet_rec.jt_finish THEN
        RETURN FALSE, "Start time must be before finish time"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_key_valid()

    -- when adding, test that primary key value is unique
    IF lib_job_timesheet.exists(m_job_timesheet_rec.jt_code, m_job_timesheet_rec.jt_idx) THEN
        RETURN FALSE, "Record already exists"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_default()

    LET m_job_timesheet_rec.jt_code = jt_code_default()
    LET m_job_timesheet_rec.jt_idx = jt_idx_default()
    LET m_job_timesheet_rec.jt_start = jt_start_default()
    LET m_job_timesheet_rec.jt_finish = jt_finish_default()
    LET m_job_timesheet_rec.jt_charge_code_id = jt_charge_code_id_default()
    LET m_job_timesheet_rec.jt_text = jt_text_default()
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION jt_code_default()
    DEFINE l_default LIKE job_timesheet.jt_code
    LET l_default = m_jh_code
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jt_code_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_timesheet_rec.jt_code IS NULL THEN
        RETURN FALSE, "Job Code must be entered"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jt_idx_default()
    DEFINE l_default LIKE job_timesheet.jt_idx

    -- maxmimum line number + 1
    LET l_default = NVL(lib_job_timesheet.jt_idx_max(m_job_timesheet_rec.jt_code), 0) + 1
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jt_idx_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_timesheet_rec.jt_idx IS NULL THEN
        RETURN FALSE, "Timesheet Index must be entered"
    END IF
    IF m_job_timesheet_rec.jt_idx < 1 THEN
        RETURN FALSE, "Timesheet Index must be greater than 0"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jt_start_default()
    DEFINE l_default LIKE job_timesheet.jt_start

    LET l_default = CURRENT YEAR TO MINUTE
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jt_start_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_timesheet_rec.jt_start IS NULL THEN
        RETURN FALSE, "Start time must be entered"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jt_finish_default()
    DEFINE l_default LIKE job_timesheet.jt_finish

    LET l_default = CURRENT YEAR TO MINUTE
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jt_finish_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_timesheet_rec.jt_finish IS NULL THEN
        RETURN FALSE, "Finish time must be entered"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jt_charge_code_id_default()
    DEFINE l_default LIKE job_timesheet.jt_charge_code_id

    LET l_default = 1
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jt_charge_code_id_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_timesheet_rec.jt_charge_code_id IS NULL THEN
        RETURN FALSE, "Charge Code must be entered"
    END IF
    IF m_job_timesheet_rec.jt_charge_code_id MATCHES "[012]" THEN
        #ok
    ELSE
        RETURN FALSE, "Charge Code must be valid"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jt_text_default()
    DEFINE l_default LIKE job_timesheet.jt_text

    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jt_text_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION db_select()
    TRY
        SELECT * INTO m_job_timesheet_rec.* FROM job_timesheet
            WHERE job_timesheet.jt_code = m_job_timesheet_rec.jt_code AND job_timesheet.jt_idx = m_job_timesheet_rec.jt_idx
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_insert()

    TRY
        INSERT INTO job_timesheet VALUES(m_job_timesheet_rec.*)
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_update()

    TRY
        UPDATE job_timesheet SET job_timesheet.* = m_job_timesheet_rec.*
            WHERE job_timesheet.jt_code = m_job_timesheet_rec.jt_code AND job_timesheet.jt_idx = m_job_timesheet_rec.jt_idx
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_delete()

    TRY
        DELETE FROM job_timesheet
            WHERE job_timesheet.jt_code = m_job_timesheet_rec.jt_code AND job_timesheet.jt_idx = m_job_timesheet_rec.jt_idx
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

FUNCTION populate_charge_code_id(cb ui.combobox)
    CALL cb.clear()
    CALL cb.addItem("S", "S-Standard")
    CALL cb.addItem("F", "F-FOC")
    CALL cb.addItem("O", "O-Overtime")
END FUNCTION
