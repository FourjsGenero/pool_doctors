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
IMPORT FGL lib_job_photo

SCHEMA pool_doctors

TYPE job_photo_type RECORD LIKE job_photo.*

PUBLIC DEFINE m_job_photo_rec job_photo_type -- used to edit a single row

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
        -- take photo on way into screen
        TRY
            CALL ui.interface.frontcall("mobile", "takePhoto", [], m_job_photo_rec.jp_photo)
        CATCH
            -- See if we can default to selecting a file in case device does not have camera
            TRY
                CALL ui.Interface.frontCall(
                    "standard", "openFile", ["", "Images", "*.png *.jpg", "Select photo"], m_job_photo_rec.jp_photo)
            CATCH
                LET l_error_text = "An error occured taking the photo"
            END TRY
        END TRY
        LET l_ok = m_job_photo_rec.jp_photo IS NOT NULL
    END IF
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

FUNCTION update(l_jp_code, l_jp_idx)
    DEFINE l_jp_code LIKE job_photo.jp_code
    DEFINE l_jp_idx LIKE job_photo.jp_idx
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_job_photo_rec.jp_code = l_jp_code
    LET m_job_photo_rec.jp_idx = l_jp_idx
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

FUNCTION view(l_jp_code, l_jp_idx)
    DEFINE l_jp_code LIKE job_photo.jp_code
    DEFINE l_jp_idx LIKE job_photo.jp_idx

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET m_job_photo_rec.jp_code = l_jp_code
    LET m_job_photo_rec.jp_idx = l_jp_idx
    CALL db_select() RETURNING l_ok, l_error_text
    IF l_ok THEN
        CALL open_window()
        CALL ui_view()
        CALL close_window()
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION delete(l_jp_code, l_jp_idx)
    DEFINE l_jp_code LIKE job_photo.jp_code
    DEFINE l_jp_idx LIKE job_photo.jp_idx

    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    DEFINE l_warning BOOLEAN
    DEFINE l_warning_text STRING

    LET m_job_photo_rec.jp_code = l_jp_code
    LET m_job_photo_rec.jp_idx = l_jp_idx
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
    OPEN WINDOW job_photo_grid WITH FORM "job_photo_grid"
    LET w = ui.window.getcurrent()
    LET f = w.getform()
END FUNCTION

PRIVATE FUNCTION close_window()
    CLOSE WINDOW job_photo_grid
END FUNCTION

PRIVATE FUNCTION ui_edit()
    DEFINE l_ok, l_error_text STRING

    INPUT BY NAME m_job_photo_rec.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS = TRUE)

        &define after_field(p1) after field p1 \
                                    call p1 ## _valid() returning l_ok, l_error_text \
                                    if not l_ok then \
                                        call lib_ui.show_error(l_error_text, false) \
                                        next field p1 \
                                    end if
        after_field(jp_code)
        after_field(jp_idx)
        after_field(jp_photo)
        after_field(jp_text)
        after_field(jp_when)
        after_field(jp_lat)
        after_field(jp_lon)

        &undef after_field

        ON ACTION cancel
            IF dialog.getfieldtouched("*") OR m_mode = "add" THEN
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
                field_valid(jp_code)
                field_valid(jp_idx)
                CALL record_key_valid() RETURNING l_ok, l_error_text
                IF NOT l_ok THEN
                    CALL lib_ui.show_error(l_error_text, FALSE)
                    NEXT FIELD CURRENT
                END IF
            END IF

            field_valid(jp_photo)
            field_valid(jp_text)
            field_valid(jp_when)
            field_valid(jp_lat)
            field_valid(jp_lon)

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

    DISPLAY BY NAME m_job_photo_rec.*
END FUNCTION

PRIVATE FUNCTION record_delete_warning()

    RETURN FALSE, ""
END FUNCTION

PRIVATE FUNCTION record_valid()

    -- validation involving two or more fields
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_key_valid()

    -- when adding, test that primary key value is unique
    IF lib_job_photo.exists(m_job_photo_rec.jp_code, m_job_photo_rec.jp_idx) THEN
        RETURN FALSE, "Record already exists"
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION record_default()
    DEFINE result STRING

    LET m_job_photo_rec.jp_code = jp_code_default()
    LET m_job_photo_rec.jp_idx = jp_idx_default()

    CALL ui.interface.frontcall("mobile", "getgeolocation", [], [result, m_job_photo_rec.jp_lat, m_job_photo_rec.jp_lon])

    LET m_job_photo_rec.jp_photo = jp_photo_default()
    LET m_job_photo_rec.jp_text = jp_text_default()
    LET m_job_photo_rec.jp_when = jp_when_default()
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION jp_code_default()
    DEFINE l_default LIKE job_photo.jp_code

    LET l_default = m_jh_code
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_code_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_photo_rec.jp_code IS NULL THEN
        RETURN FALSE, "Job Code must be entered"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jp_idx_default()
    DEFINE l_default LIKE job_photo.jp_idx

    -- maxmimum line number + 1
    LET l_default = NVL(lib_job_photo.jp_idx_max(m_job_photo_rec.jp_code), 0) + 1
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_idx_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_photo_rec.jp_idx IS NULL THEN
        RETURN FALSE, "Job Photo Index must be entered"
    END IF
    IF m_job_photo_rec.jp_idx < 1 THEN
        RETURN FALSE, "Job Photo Index must be greater than 0"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jp_photo_default()
    DEFINE l_default LIKE job_photo.jp_photo

    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_photo_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jp_text_default()
    DEFINE l_default LIKE job_photo.jp_text

    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_text_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jp_lat_default()
    DEFINE l_default LIKE job_photo.jp_lat

    -- set by geoLocation frontcall
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_lat_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_photo_rec.jp_lat < -90 OR m_job_photo_rec.jp_lat > 90 THEN
        RETURN FALSE, "Latitude must be valid"
    END IF

    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jp_lon_default()
    DEFINE l_default LIKE job_photo.jp_lon

    -- set by geoLocation frontcall
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_lon_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    LET l_ok = TRUE
    IF m_job_photo_rec.jp_lon < -180 OR m_job_photo_rec.jp_lon > 180 THEN
        RETURN FALSE, "Longitude must be valid"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION jp_when_default()
    DEFINE l_default LIKE job_photo.jp_when

    LET l_default = CURRENT YEAR TO SECOND
    RETURN l_default
END FUNCTION

PRIVATE FUNCTION jp_when_valid()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING

    LET l_ok = TRUE
    IF m_job_photo_rec.jp_when > CURRENT THEN
        RETURN FALSE, "When must be in the past"
    END IF
    RETURN l_ok, l_error_text
END FUNCTION

PRIVATE FUNCTION db_select()

    TRY
        SELECT * INTO m_job_photo_rec.* FROM job_photo
            WHERE job_photo.jp_code = m_job_photo_rec.jp_code AND job_photo.jp_idx = m_job_photo_rec.jp_idx
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_insert()

    TRY
        INSERT INTO job_photo VALUES(m_job_photo_rec.*)
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_update()

    TRY
        UPDATE job_photo SET job_photo.* = m_job_photo_rec.*
            WHERE job_photo.jp_code = m_job_photo_rec.jp_code AND job_photo.jp_idx = m_job_photo_rec.jp_idx
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION db_delete()

    TRY
        DELETE FROM job_photo WHERE job_photo.jp_code = m_job_photo_rec.jp_code AND job_photo.jp_idx = m_job_photo_rec.jp_idx
    CATCH
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    RETURN TRUE, ""
END FUNCTION
