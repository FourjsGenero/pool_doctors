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
IMPORT FGL job_header_grid

SCHEMA pool_doctors

TYPE job_header_type RECORD LIKE job_header.*
DEFINE m_job_header_arr DYNAMIC ARRAY OF job_header_type -- used to display multiple rows
DEFINE m_arr DYNAMIC ARRAY OF RECORD
    major STRING,
    minor STRING,
    img STRING
END RECORD

DEFINE w ui.window
DEFINE f ui.form

DEFINE m_toggle STRING
DEFINE m_filter STRING
DEFINE m_orderby STRING

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

---- Control ----
FUNCTION list()

    LET m_toggle = NVL(m_toggle, "job_code")

    OPEN WINDOW job_header_list WITH FORM "job_header_list"
    LET w = ui.Window.getCurrent()
    LET f = w.getform()

    CALL db_populate()
    CALL ui_populate()
    CALL ui_list()

    CLOSE WINDOW job_header_list
END FUNCTION

---- User Interface ----
PRIVATE FUNCTION ui_populate()
    DEFINE i INTEGER

    CALL m_arr.clear()
    FOR i = 1 TO m_job_header_arr.getLength()
        CALL ui_populate_row(i)
    END FOR
END FUNCTION

PRIVATE FUNCTION ui_populate_row(l_row)
    DEFINE l_row INTEGER

    CASE m_toggle
        WHEN "job_code"
            LET m_arr[l_row].major =
                SFMT("%1 (%2)",
                    lib_customer.lookup_cm_name(m_job_header_arr[l_row].jh_customer), m_job_header_arr[l_row].jh_customer CLIPPED)
            LET m_arr[l_row].minor = "Job:", m_job_header_arr[l_row].jh_code
            LET m_arr[l_row].img = status2image(m_job_header_arr[l_row].jh_status)
        WHEN "job_created"
            LET m_arr[l_row].major =
                SFMT("%1 (%2)",
                    lib_customer.lookup_cm_name(m_job_header_arr[l_row].jh_customer), m_job_header_arr[l_row].jh_customer CLIPPED)
            LET m_arr[l_row].minor =
                SFMT("Job Created: %1 %2",
                    DATE(m_job_header_arr[l_row].jh_date_created), TIME(m_job_header_arr[l_row].jh_date_created))
            LET m_arr[l_row].img = status2image(m_job_header_arr[l_row].jh_status)
    END CASE
END FUNCTION

PRIVATE FUNCTION ui_list()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING
    DEFINE l_popup_value_select BOOLEAN

    DISPLAY ARRAY m_arr TO scr.*
        ATTRIBUTES(UNBUFFERED, ACCEPT = FALSE, CANCEL = TRUE, DOUBLECLICK = select, ACCESSORYTYPE = DISCLOSUREINDICATOR)

        BEFORE DISPLAY
            IF m_arr.getlength() = 0 THEN
                CALL lib_ui.show_message("No jobs loaded.  Return to front screen and sync data", TRUE)
            END IF

        ON ACTION select
            CALL job_header_grid.view_job(m_job_header_arr[arr_curr()].jh_code) RETURNING l_ok, l_err_text

            -- repopulate upon return
            IF l_ok THEN
                CALL db_populate()
                CALL ui_populate()
            ELSE
                CALL lib_ui.show_error(l_err_text, TRUE)
            END IF

        ON ACTION toggle
            LET l_popup_value_select = TRUE
            MENU "Display Detail" ATTRIBUTES(STYLE = "popup")
                ON ACTION job_code ATTRIBUTES(TEXT = "Job Code")
                    LET m_toggle = "job_code"
                ON ACTION job_created ATTRIBUTES(TEXT = "Job Created")
                    LET m_toggle = "job_created"
                ON ACTION cancel
                    LET l_popup_value_select = FALSE
            END MENU
            IF l_popup_value_select THEN
                CALL ui_populate()
            END IF

        ON ACTION filter
            LET l_popup_value_select = TRUE
            MENU "Filter" ATTRIBUTES(STYLE = "popup")
                ON ACTION all ATTRIBUTES(TEXT = "All")
                    INITIALIZE m_filter TO NULL
                ON ACTION new ATTRIBUTES(TEXT = "New")
                    LET m_filter = "jh_status = 'O'"
                ON ACTION inprogress ATTRIBUTES(TEXT = "In-Progress")
                    LET m_filter = "jh_status = 'I'"
                ON ACTION new_inprogress ATTRIBUTES(TEXT = "New and in-progress")
                    LET m_filter = "jh_status != 'X'"
                ON ACTION complete
                    ATTRIBUTES(TEXT = "Complete", IMAGE = "") -- TODO, added image so no iamge defined, then it aligns
                    LET m_filter = "jh_status = 'X'"
                ON ACTION cancel
                    LET l_popup_value_select = FALSE
            END MENU

            IF l_popup_value_select THEN
                CALL db_populate()
                CALL ui_populate()
            END IF

        ON ACTION order
            LET l_popup_value_select = TRUE
            MENU "Order" ATTRIBUTES(STYLE = "popup")
                ON ACTION job_number ATTRIBUTES(TEXT = "Job Number")
                    LET m_orderby = "jh_code"
                ON ACTION date_created ATTRIBUTES(TEXT = "Newest to Oldest")
                    LET m_orderby = "jh_date_created desc"
                ON ACTION cancel
                    LET l_popup_value_select = FALSE
            END MENU

            IF l_popup_value_select THEN
                CALL db_populate()
                CALL ui_populate()
            END IF

    END DISPLAY
    IF int_flag THEN
        LET int_flag = 0
    END IF
END FUNCTION

PRIVATE FUNCTION status2image(s)
    DEFINE s CHAR(1)

    -- Map job status to an image
    CASE
        WHEN s = "O"
            RETURN "clock-1"
        WHEN s = "I"
            RETURN "clock-2"
        WHEN s = "X"
            RETURN "clock-3"
        OTHERWISE
            RETURN NULL
    END CASE
END FUNCTION

---- Database ----
PRIVATE FUNCTION db_populate()
    DEFINE l_sql STRING
    DEFINE l_rec job_header_type

    CALL m_job_header_arr.clear()
    LET l_sql = "select * from job_header"
    IF m_filter.getlength() > 0 THEN
        LET l_sql = l_sql, " where ", m_filter
    END IF
    IF m_orderby.getlength() > 0 THEN
        LET l_sql = l_sql, " order by ", m_orderby
    END IF
    DECLARE job_header_list_curs CURSOR FROM l_sql
    FOREACH job_header_list_curs INTO l_rec.*
        LET m_job_header_arr[m_job_header_arr.getlength() + 1].* = l_rec.*
    END FOREACH
END FUNCTION
