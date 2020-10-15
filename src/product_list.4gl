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

SCHEMA "pool_doctors"

TYPE product_type RECORD LIKE product.*

DEFINE m_product_arr DYNAMIC ARRAY OF product_type
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

FUNCTION select()
    DEFINE l_pr_code LIKE product.pr_code

    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    LET m_toggle = NVL(m_toggle, "pr_code")

    OPEN WINDOW product_list WITH FORM "product_list" ATTRIBUTES(TYPE = POPUP) #style="dialog")
    LET w = ui.window.getcurrent()
    LET f = w.getform()

    CALL db_populate() RETURNING l_ok, l_err_text
    IF l_ok THEN
        CALL ui_populate()
        LET l_pr_code = ui_list()
    ELSE
        CALL lib_ui.show_error(l_err_text, TRUE)
    END IF

    CLOSE WINDOW product_list

    RETURN l_pr_code
END FUNCTION

PRIVATE FUNCTION ui_populate()
    DEFINE i INTEGER

    CALL m_arr.clear()
    FOR i = 1 TO m_product_arr.getLength()
        CALL ui_populate_row(i)
    END FOR
END FUNCTION

PRIVATE FUNCTION ui_populate_row(l_row)
    DEFINE l_row INTEGER

    CASE m_toggle
        WHEN "pr_code"
            LET m_arr[l_row].major = m_product_arr[l_row].pr_code CLIPPED
            LET m_arr[l_row].minor = m_product_arr[l_row].pr_desc CLIPPED
            LET m_arr[l_row].img = ""
        WHEN "pr_desc"
            LET m_arr[l_row].major = m_product_arr[l_row].pr_desc CLIPPED
            LET m_arr[l_row].minor = m_product_arr[l_row].pr_code CLIPPED
            LET m_arr[l_row].img = ""
    END CASE
END FUNCTION

PRIVATE FUNCTION ui_list()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    DEFINE l_popup_value_select BOOLEAN

    DISPLAY ARRAY m_arr TO scr.* ATTRIBUTES(UNBUFFERED, ACCESSORYTYPE = CHECKMARK, DOUBLECLICK = accept)

        ON ACTION toggle
            LET l_popup_value_select = TRUE
            MENU "Display Detail" ATTRIBUTES(STYLE = "popup")
                ON ACTION pr_code ATTRIBUTES(TEXT = "Code")
                    LET m_toggle = "pr_code"
                ON ACTION pr_desc ATTRIBUTES(TEXT = "Description")
                    LET m_toggle = "pr_desc"
                ON ACTION cancel
                    LET l_popup_value_select = FALSE
            END MENU
            IF l_popup_value_select THEN
                CALL ui_populate()
            END IF

        ON ACTION order
            LET l_popup_value_select = TRUE
            MENU "Order" ATTRIBUTES(STYLE = "popup")
                ON ACTION pr_code ATTRIBUTES(TEXT = "Code")
                    LET m_orderby = "pr_code"
                ON ACTION pr_desc ATTRIBUTES(TEXT = "Description")
                    LET m_orderby = "pr_desc"
                ON ACTION cancel
                    LET l_popup_value_select = FALSE
            END MENU
            IF l_popup_value_select THEN
                CALL db_populate() RETURNING l_ok, l_err_text
                IF l_ok THEN
                    CALL ui_populate()
                ELSE
                    CALL lib_ui.show_error(l_err_text, TRUE)
                END IF
            END IF

    END DISPLAY
    IF int_flag THEN
        LET int_flag = 0
        RETURN NULL
    ELSE
        RETURN m_product_arr[arr_curr()].pr_code
    END IF
END FUNCTION

PRIVATE FUNCTION db_populate()
    DEFINE l_sql STRING
    DEFINE l_rec product_type

    TRY
        CALL m_product_arr.clear()
        LET l_sql = "select * from product"
        IF m_filter.getLength() > 0 THEN
            LET l_sql = l_sql, " where ", m_filter
        END IF
        IF m_orderby.getlength() > 0 THEN
            LET l_sql = l_sql, " order by ", m_orderby
        END IF
        DECLARE product_list_curs CURSOR FROM l_sql
        FOREACH product_list_curs INTO l_rec.*
            LET m_product_arr[m_product_arr.getLength() + 1].* = l_rec.*
        END FOREACH
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION
