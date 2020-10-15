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

IMPORT FGL lib_customer
IMPORT FGL lib_job_detail
IMPORT FGL lib_job_note
IMPORT FGL lib_job_photo
IMPORT FGL lib_job_timesheet

IMPORT FGL customer_grid
IMPORT FGL job_header_complete
IMPORT FGL job_detail_list
IMPORT FGL job_photo_list
IMPORT FGL job_note_list
IMPORT FGL job_timesheet_list

SCHEMA pool_doctors

TYPE job_header_type RECORD LIKE job_header.*

DEFINE m_job_header_rec job_header_type

DEFINE w ui.window
DEFINE f ui.form

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

---- Control ----
FUNCTION view_job(l_jh_code)
    DEFINE l_jh_code LIKE job_header.jh_code

    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    LET m_job_header_rec.jh_code = l_jh_code
    CALL db_select() RETURNING l_ok, l_err_text
    IF l_ok THEN
        DISPLAY ui.Interface.getFrontEndName()

        OPEN WINDOW job_header_grid WITH FORM "job_header_grid"
        LET w = ui.Window.getCurrent()
        LET f = w.getForm()
        CALL ui_view()
        CLOSE WINDOW job_header_grid
    ELSE
        CALL lib_ui.show_error("Job Record not found", TRUE)
    END IF
    RETURN l_ok, l_err_text
END FUNCTION

---- User Interface ----
PRIVATE FUNCTION ui_view()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    LET m_job_header_rec.jh_date_created = CURRENT
    DISPLAY BY NAME m_job_header_rec.jh_code, m_job_header_rec.jh_customer, m_job_header_rec.jh_date_created

    DISPLAY SFMT("%1 (%2)", lib_customer.lookup_cm_name(m_job_header_rec.jh_customer), m_job_header_rec.jh_customer CLIPPED)
        TO jh_customer

    DISPLAY SFMT("%1 Parts", lib_job_detail.count(m_job_header_rec.jh_code)) TO lines_count
    DISPLAY SFMT("%1 Notes", lib_job_note.count(m_job_header_rec.jh_code)) TO notes_count
    DISPLAY SFMT("%1 Photos", lib_job_photo.count(m_job_header_rec.jh_code)) TO photos_count
    DISPLAY SFMT("%1 Timesheet Lines", lib_job_timesheet.count(m_job_header_rec.jh_code)) TO timesheet_count

    MENU
        BEFORE MENU
            CALL state(dialog)

        ON ACTION cancel
            EXIT MENU

        ON ACTION customer
            CALL customer_grid.view_customer(m_job_header_rec.jh_customer) RETURNING l_ok, l_err_text

        ON ACTION lines
            IF m_job_header_rec.jh_status MATCHES "[IX]" THEN
                CALL job_detail_list.maintain_job(m_job_header_rec.jh_code)
                DISPLAY SFMT("%1 Parts", lib_job_detail.count(m_job_header_rec.jh_code)) TO lines_count
            ELSE
                CALL lib_ui.show_message("Tap Start before entering job data", TRUE)
            END IF

        ON ACTION photo
            IF m_job_header_rec.jh_status MATCHES "[IX]" THEN
                CALL job_photo_list.maintain_job(m_job_header_rec.jh_code)
                DISPLAY SFMT("%1 Photos", lib_job_photo.count(m_job_header_rec.jh_code)) TO photos_count
            ELSE
                CALL lib_ui.show_message("Tap Start before entering job data", TRUE)
            END IF

        ON ACTION notes
            IF m_job_header_rec.jh_status MATCHES "[IX]" THEN
                CALL job_note_list.maintain_job(m_job_header_rec.jh_code)
                DISPLAY SFMT("%1 Notes", lib_job_note.count(m_job_header_rec.jh_code)) TO notes_count
            ELSE
                CALL lib_ui.show_message("Tap Start before entering job data", TRUE)
            END IF

        ON ACTION time
            IF m_job_header_rec.jh_status MATCHES "[IX]" THEN
                CALL job_timesheet_list.maintain_job(m_job_header_rec.jh_code)
                DISPLAY SFMT("%1 Timesheet Lines", lib_job_timesheet.count(m_job_header_rec.jh_code)) TO timesheet_count
            ELSE
                CALL lib_ui.show_message("Tap Start before entering job data", TRUE)
            END IF

        ON ACTION start
            CALL db_update_start() RETURNING l_ok, l_err_text
            IF NOT l_ok THEN
                CALL lib_ui.show_error(SFMT("Error starting job %1", l_err_text), TRUE)
            END IF
            CALL state(dialog)

        ON ACTION complete
            CALL job_header_complete.complete(m_job_header_rec.jh_code) RETURNING l_ok, l_err_text
            IF NOT l_ok THEN
                CONTINUE MENU
            END IF
            CALL db_select() RETURNING l_ok, l_err_text
            IF NOT l_ok THEN
                -- shouldn't occur
            END IF
            CALL state(dialog)

    END MENU
END FUNCTION

PRIVATE FUNCTION state(d)
    DEFINE d ui.dialog

    CALL d.setActionActive("start", m_job_header_rec.jh_status = "O")
    CALL d.setActionActive("complete", m_job_header_rec.jh_status = "I")
END FUNCTION

---- Database ----
PRIVATE FUNCTION db_select()
    TRY
        SELECT * INTO m_job_header_rec.* FROM job_header WHERE job_header.jh_code = m_job_header_rec.jh_code
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_update_start()
    LET m_job_header_rec.jh_status = "I"
    TRY
        UPDATE job_header SET jh_status = m_job_header_rec.jh_status WHERE job_header.jh_code = m_job_header_rec.jh_code
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION
