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

IMPORT FGL lib_job_header
IMPORT FGL lib_product

IMPORT FGL job_note_grid

SCHEMA pool_doctors

TYPE job_note_type RECORD LIKE job_note.*
DEFINE m_job_note_arr DYNAMIC ARRAY OF job_note_type

DEFINE m_jh_code LIKE job_header.jh_code

DEFINE w ui.window
DEFINE f ui.form

DEFINE m_arr DYNAMIC ARRAY OF RECORD
    major STRING,
    minor STRING,
    img STRING
END RECORD

DEFINE m_filter STRING

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

FUNCTION maintain()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    OPEN WINDOW job_note_list WITH FORM "job_note_list"
    LET w = ui.window.getcurrent()
    LET f = w.getform()

    CALL db_populate() RETURNING l_ok, l_err_text
    IF l_ok THEN
        CALL ui_populate()
        CALL ui_list()
    ELSE
        CALL lib_ui.show_error(l_err_text, TRUE)
    END IF

    CLOSE WINDOW job_note_list
END FUNCTION

FUNCTION maintain_job(l_jn_code)
    DEFINE l_jn_code LIKE job_note.jn_code

    LET m_jh_code = l_jn_code
    LET m_filter = SFMT("job_note.jn_code = '%1'", l_jn_code CLIPPED)
    CALL maintain()
END FUNCTION

PRIVATE FUNCTION ui_populate()
    DEFINE i INTEGER

    CALL m_arr.clear()
    FOR i = 1 TO m_job_note_arr.getLength()
        CALL ui_populate_row(i)
    END FOR
END FUNCTION

PRIVATE FUNCTION ui_populate_row(l_row)
    DEFINE l_row INTEGER

    LET m_arr[l_row].major = m_job_note_arr[l_row].jn_note CLIPPED
    LET m_arr[l_row].minor = ""
    LET m_arr[l_row].img = ""
END FUNCTION

PRIVATE FUNCTION ui_list()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    DEFINE l_row INTEGER
    DEFINE l_editable BOOLEAN

    DISPLAY ARRAY m_arr TO scr.*
        ATTRIBUTES(UNBUFFERED, ACCEPT = FALSE, CANCEL = TRUE, DOUBLECLICK = update, ACCESSORYTYPE = DISCLOSUREINDICATOR)

        BEFORE DISPLAY
            LET l_editable = lib_job_header.editable(m_jh_code)
            CALL dialog.setActionActive("append", l_editable)
            CALL dialog.setActionActive("delete", l_editable)
            IF l_editable AND m_arr.getLength() = 0 THEN
                CALL lib_ui.show_message("Tap + to add", FALSE)
            END IF

        BEFORE ROW
            LET l_row = dialog.getcurrentrow("scr")

        ON APPEND
            CALL job_note_grid.add(m_jh_code) RETURNING l_ok, l_error_text
            IF NOT l_ok THEN
                CALL lib_ui.show_error(l_error_text, TRUE)
                LET int_flag = TRUE
            ELSE
                LET m_job_note_arr[m_job_note_arr.getlength() + 1].* = job_note_grid.m_job_note_rec.*
                CALL ui_populate_row(m_job_note_arr.getlength())
            END IF

        ON UPDATE
            IF lib_job_header.editable(m_job_note_arr[l_row].jn_code) THEN
                CALL job_note_grid.update(m_job_note_arr[l_row].jn_code, m_job_note_arr[l_row].jn_idx) RETURNING l_ok, l_error_text
                IF NOT l_ok THEN
                    CALL lib_ui.show_error(l_error_text, TRUE)
                    LET int_flag = TRUE
                END IF
                LET m_job_note_arr[l_row].* = job_note_grid.m_job_note_rec.*
                CALL ui_populate_row(l_row)
            ELSE
                -- if we cant update, view it instead
                CALL job_note_grid.view(m_job_note_arr[l_row].jn_code, m_job_note_arr[l_row].jn_idx) RETURNING l_ok, l_error_text
            END IF

        ON DELETE
            CALL job_note_grid.delete(m_job_note_arr[l_row].jn_code, m_job_note_arr[l_row].jn_idx) RETURNING l_ok, l_error_text
            IF NOT l_ok THEN
                CALL lib_ui.show_error(l_error_text, TRUE)
                LET int_flag = TRUE
            END IF
            CALL m_job_note_arr.deleteElement(l_row)

    END DISPLAY
    IF int_flag THEN
        LET int_flag = 0
    END IF
END FUNCTION

PRIVATE FUNCTION db_populate()
    DEFINE l_sql STRING
    DEFINE l_rec job_note_type

    TRY
        CALL m_job_note_arr.clear()
        LET l_sql = "select * from job_note"
        IF m_filter.getLength() > 0 THEN
            LET l_sql = l_sql, " where ", m_filter
        END IF

        DECLARE job_note_list_curs CURSOR FROM l_sql
        FOREACH job_note_list_curs INTO l_rec.*
            LET m_job_note_arr[m_job_note_arr.getLength() + 1].* = l_rec.*
        END FOREACH
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

-- there is a bug in dependency diagram which doesn't show links well if the
-- called function has the same name in two different import fgl modules
-- workaround by adding a functon with a unique name
-- this function can be removed when bug GST-12511 fixed
FUNCTION job_note_list()
    # do nothing,  never executed
END FUNCTION
