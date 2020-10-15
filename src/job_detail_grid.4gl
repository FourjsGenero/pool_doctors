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

IMPORT FGL product_list

IMPORT FGL lib_product
IMPORT FGL lib_job_detail

SCHEMA pool_doctors

TYPE job_detail_type RECORD LIKE job_detail.*

PUBLIC DEFINE m_job_detail_rec job_detail_type -- used to edit a single row

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
                CALL lib_ui.show_error(SFMT("Unable to add row\n%1", l_error_text), TRUE)
            END IF
        END IF
        CALL close_window()
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION update(l_jd_code, l_jd_line)
    DEFINE l_jd_code LIKE job_detail.jd_code
    DEFINE l_jd_line LIKE job_detail.jd_line

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_job_detail_rec.jd_code = l_jd_code
    LET m_job_detail_rec.jd_line = l_jd_line
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

FUNCTION view(l_jd_code, l_jd_line)
    DEFINE l_jd_code LIKE job_detail.jd_code
    DEFINE l_jd_line LIKE job_detail.jd_line

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_job_detail_rec.jd_code = l_jd_code
    LET m_job_detail_rec.jd_line = l_jd_line
    CALL db_select() RETURNING l_ok, l_error_text
    IF l_ok THEN
        CALL open_window()
        CALL ui_view()
        CALL close_window()
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION delete(l_jd_code, l_jd_line)
    DEFINE l_jd_code LIKE job_detail.jd_code
    DEFINE l_jd_line LIKE job_detail.jd_line

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    DEFINE l_warning BOOLEAN
    DEFINE l_warning_text STRING

    LET m_job_detail_rec.jd_code = l_jd_code
    LET m_job_detail_rec.jd_line = l_jd_line
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
                LET l_error_text = "Delete Cancelled"
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
    OPEN WINDOW job_detail_grid WITH FORM "job_detail_grid"
    LET w = ui.window.getcurrent()
    LET f = w.getform()
    CALL combo_populate_jd_status(ui.combobox.forname("formonly.jd_status"))
END FUNCTION

PRIVATE FUNCTION close_window()
    CLOSE WINDOW job_detail_grid
END FUNCTION

PRIVATE FUNCTION ui_edit()
    DEFINE l_ok, l_error_text STRING

    INPUT BY NAME m_job_detail_rec.jd_code, m_job_detail_rec.jd_line, m_job_detail_rec.jd_product, m_job_detail_rec.jd_qty,
        m_job_detail_rec.jd_status
        ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS = TRUE)

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call lib_ui.show_error(l_error_text,false) \
                                        next field p1 \
                                    end if

        after_field(jd_code)
        after_field(jd_line)
        after_field(jd_product)
        after_field(jd_qty)
        after_field(jd_status)
        &undef after_field

        ON ACTION zoom INFIELD jd_product
            LET m_job_detail_rec.jd_product = NVL(product_list.select(), m_job_detail_rec.jd_product)
            CALL dialog.setFieldTouched("jd_product", TRUE)

        ON ACTION barcode
            CALL do_barcode_read()
            CALL dialog.setFieldTouched("jd_product", TRUE)

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

            -- test key fields
            IF m_mode = "add" THEN
                field_valid(jd_code)
                field_valid(jd_line)
                CALL record_key_valid() RETURNING l_ok, l_error_text
                IF NOT l_ok THEN
                    CALL lib_ui.show_error(l_error_text, FALSE)
                    NEXT FIELD CURRENT
                END IF
            END IF

            -- test data fields
            field_valid(jd_product)
            field_valid(jd_qty)
            field_valid(jd_status)

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

    DISPLAY BY NAME m_job_detail_rec.jd_code, m_job_detail_rec.jd_line, m_job_detail_rec.jd_product, m_job_detail_rec.jd_qty,
        m_job_detail_rec.jd_status
END FUNCTION

FUNCTION combo_populate_jd_status(l_cb)
    DEFINE l_cb ui.combobox

    CALL l_cb.clear()
    CALL l_cb.additem("0", "Entered")
    CALL l_cb.additem("1", "Delivered")
    CALL l_cb.additem("2", "Invoiced")
END FUNCTION

PRIVATE FUNCTION do_barcode_read()
    DEFINE l_pr_barcode LIKE product.pr_barcode
    DEFINE l_pr_code LIKE product.pr_code
    DEFINE l_pr_desc LIKE product.pr_desc
    DEFINE l_barcode_type STRING

    CALL ui.interface.frontcall("mobile", "scanBarCode", [], [l_pr_barcode, l_barcode_type])
    IF l_pr_barcode IS NOT NULL THEN
        LET l_pr_code = lib_product.find_from_barcode(l_pr_barcode)
        IF l_pr_code IS NOT NULL THEN
            LET l_pr_desc = lib_product.lookup_pr_desc(l_pr_code)
            CALL lib_ui.show_message(SFMT("Barcode read is %1\nproduct is %2(%3)", l_pr_barcode, l_pr_code, l_pr_desc), TRUE)
            LET m_job_detail_rec.jd_product = l_pr_code
        ELSE
            CALL lib_ui.show_error("Barcode is not in database", TRUE)
        END IF
    END IF
END FUNCTION

PRIVATE FUNCTION record_delete_warning()
    -- Sample delete warning, don't delete line if has certain status
    IF m_job_detail_rec.jd_status = "0" THEN
        #ok to delete
    ELSE
        RETURN TRUE, "Job Line has status 1"
    END IF
    RETURN FALSE, ""
END FUNCTION

PRIVATE FUNCTION record_valid()

    -- validation involving two or more fields
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_key_valid()

    -- when adding, test that primary key value is unique
    IF lib_job_detail.exists(m_job_detail_rec.jd_code, m_job_detail_rec.jd_line) THEN
        RETURN FALSE, "Record already exists"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_default()
    LET m_job_detail_rec.jd_code = jd_code_default()
    LET m_job_detail_rec.jd_line = jd_line_default()
    LET m_job_detail_rec.jd_product = jd_product_default()
    LET m_job_detail_rec.jd_qty = jd_qty_default()
    LET m_job_detail_rec.jd_status = jd_status_default()
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION jd_code_default()
    DEFINE l_default LIKE job_detail.jd_code
    LET l_default = m_jh_code
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jd_code_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_detail_rec.jd_code IS NULL THEN
        RETURN FALSE, "Job Code must be entered"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jd_line_default()
    DEFINE l_default LIKE job_detail.jd_line

    -- maxmimum line number + 1
    LET l_default = NVL(lib_job_detail.jd_line_max(m_job_detail_rec.jd_code), 0) + 1
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jd_line_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_detail_rec.jd_line IS NULL THEN
        RETURN FALSE, "Job Line must be entered"
    END IF
    IF m_job_detail_rec.jd_line < 1 THEN
        RETURN FALSE, "Job Line must be greater than 0"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jd_product_default()
    DEFINE l_default LIKE job_detail.jd_product

    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jd_product_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_detail_rec.jd_product IS NULL THEN
        RETURN FALSE, "Product must be entered"
    END IF
    IF NOT lib_product.exists(m_job_detail_rec.jd_product) THEN
        RETURN FALSE, "Product must be valid"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jd_qty_default()
    DEFINE l_default LIKE job_detail.jd_qty

    LET l_default = 1
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jd_qty_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_detail_rec.jd_qty IS NULL THEN
        RETURN FALSE, "Quantity must be entered"
    END IF
    IF m_job_detail_rec.jd_qty < 0 THEN
        RETURN FALSE, "Quantity must be greater than 0"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jd_status_default()
    DEFINE l_default LIKE job_detail.jd_status

    LET l_default = 0
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jd_status_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_detail_rec.jd_status IS NULL THEN
        RETURN FALSE, "Status must be entered"
    END IF
    IF m_job_detail_rec.jd_status MATCHES "[012]" THEN
        #ok
    ELSE
        RETURN FALSE, "Status must be valid"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION db_select()
    TRY
        SELECT * INTO m_job_detail_rec.* FROM job_detail
            WHERE job_detail.jd_code = m_job_detail_rec.jd_code AND job_detail.jd_line = m_job_detail_rec.jd_line
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_insert()

    TRY
        INSERT INTO job_detail VALUES(m_job_detail_rec.*)
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_update()

    TRY
        UPDATE job_detail SET job_detail.* = m_job_detail_rec.*
            WHERE job_detail.jd_code = m_job_detail_rec.jd_code AND job_detail.jd_line = m_job_detail_rec.jd_line
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_delete()

    TRY
        DELETE FROM job_detail WHERE job_detail.jd_code = m_job_detail_rec.jd_code AND job_detail.jd_line = m_job_detail_rec.jd_line
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION
