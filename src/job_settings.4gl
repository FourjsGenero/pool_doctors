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

IMPORT FGL lib_settings
IMPORT FGL lib_error
IMPORT FGL lib_ui

SCHEMA pool_doctors

DEFINE m_job_settings_rec RECORD
    js_url LIKE job_settings.js_url,
    js_group LIKE job_settings.js_group,
    js_map LIKE job_settings.js_map
END RECORD

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

---- Control ----

FUNCTION edit()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    INITIALIZE m_job_settings_rec.* TO NULL
    CALL db_select() RETURNING l_ok, l_err_text
    IF l_ok THEN
        OPEN WINDOW job_settings WITH FORM "job_settings"
        CALL ui_edit() RETURNING l_ok

        IF l_ok THEN
            CALL db_update() RETURNING l_ok, l_err_text
            IF l_ok THEN
                CALL lib_settings.populate()
            END IF
        END IF
        CLOSE WINDOW job_settings
    ELSE
        CALL lib_ui.show_error("Settings not found", TRUE)
    END IF
    RETURN l_ok, l_err_text
END FUNCTION

PRIVATE FUNCTION ui_edit()
    DEFINE l_ok, l_error_text STRING

    LET int_flag = 0 # something not setting this before i get here
    INPUT BY NAME m_job_settings_rec.js_url, m_job_settings_rec.js_group, m_job_settings_rec.js_map
        ATTRIBUTES(WITHOUT DEFAULTS = TRUE, UNBUFFERED)

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call lib_ui.show_error(l_error_text,false) \
                                        next field p1 \
                                    end if

        after_field(js_url)
        after_field(js_group)
        after_field(js_map)

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
            field_valid(js_url)
            field_valid(js_group)
            field_valid(js_map)

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

PRIVATE FUNCTION js_url_valid()

    IF m_job_settings_rec.js_url IS NULL THEN
        RETURN FALSE, "URL must be entered"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION js_group_valid()

    IF m_job_settings_rec.js_group IS NULL THEN
        RETURN FALSE, "Group must be entered"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION js_map_valid()

    IF m_job_settings_rec.js_map IS NULL THEN
        RETURN FALSE, "Map must be entered"
    END IF
    IF m_job_settings_rec.js_map >= 0 AND m_job_settings_rec.js_map <= 2 THEN
        #ok
    ELSE
        RETURN FALSE, "Map must be valid"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_valid()
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_select()
    TRY
        SELECT js_url, js_group, js_map INTO m_job_settings_rec.js_url, m_job_settings_rec.js_group, m_job_settings_rec.js_map
            FROM job_settings
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_update()
    TRY
        UPDATE job_settings
            SET js_url = m_job_settings_rec.js_url, js_group = m_job_settings_rec.js_group, js_map = m_job_settings_rec.js_map
            WHERE 1 = 1
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

FUNCTION combo_populate_map_settings(cb)
    DEFINE cb ui.ComboBox

    CALL cb.clear()
    CALL cb.addItem(0, "None")
    CALL cb.addItem(1, "geo:")
    CALL cb.addItem(2, "https://google.com/maps")
    CALL cb.addItem(3, "Google Maps App (iOS only)")
END FUNCTION
