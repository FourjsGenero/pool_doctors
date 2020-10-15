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
IMPORT FGL lib_settings
IMPORT FGL browser

IMPORT FGL job_sync
IMPORT FGL job_header_list
IMPORT FGL job_settings
IMPORT os

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

FUNCTION execute()
    OPEN WINDOW home WITH FORM "home"
    CALL home()
    CLOSE WINDOW home
END FUNCTION

PRIVATE FUNCTION home()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    MENU ""
        BEFORE MENU
            CALL dialog.setActionActive("settings", TRUE)

        ON ACTION home
            CALL job_header_list.list()

        ON ACTION settings
            MENU "" ATTRIBUTES(STYLE = "popup")
                ON ACTION edit_settings ATTRIBUTES(TEXT = "Edit Settings")
                    CALL job_settings.edit() RETURNING l_ok, l_err_text
                    IF l_ok THEN
                        CALL lib_ui.show_message(l_err_text, TRUE)
                    ELSE
                        CALL lib_ui.show_error(l_err_text, TRUE)
                    END IF

                ON ACTION random ATTRIBUTES(TEXT = "Create Random Job")
                    -- simulate the creation of a new job
                    CALL job_sync.create_random_job() RETURNING l_ok, l_err_text
                    IF l_ok THEN
                        CALL lib_ui.show_message(l_err_text, TRUE)
                    ELSE
                        CALL lib_ui.show_error(l_err_text, TRUE)
                    END IF

                ON ACTION delete_all ATTRIBUTES(TEXT = "Delete ALL Job Data")
                    CALL delete_database() RETURNING l_ok, l_err_text
                    IF l_ok THEN
                        CALL lib_ui.show_message(l_err_text, TRUE)
                    ELSE
                        CALL lib_ui.show_error(l_err_text, TRUE)
                    END IF

                ON ACTION force_error ATTRIBUTES(TEXT = "Force Error") -- used to test error handling
                    -- need to stop program terminating on error or else fails to get into App Store
                    CALL lib_error.test_mode(TRUE) -- set so does not stop program
                    DISPLAY 1 / 0 -- this will make program error
                    CALL lib_error.test_mode(FALSE)

                ON ACTION view_errorlog ATTRIBUTES(TEXT = "View Error Log")
                    CALL lib_error.view_errorlog()

                ON ACTION clear_error ATTRIBUTES(TEXT = "Clear Error Log")
                    CALL clear_errorlog() RETURNING l_ok, l_err_text
                    IF l_ok THEN
                        CALL lib_ui.show_message(l_err_text, TRUE)
                    ELSE
                        CALL lib_ui.show_error(l_err_text, TRUE)
                    END IF

            END MENU

        ON ACTION refresh
            CALL job_sync.execute() RETURNING l_ok, l_err_text
            IF l_ok THEN
                CALL lib_ui.show_message("Sync Result\n" || l_err_text, TRUE)
            ELSE
                CALL lib_ui.show_error("Sync Result\n" || l_err_text, TRUE)
            END IF

        ON ACTION help
            -- Use Supported Systems Document as example of similar sized PDF
            -- Consider using browser.browser when NULL Web Component can handle PDF
            -- I think that will be GDD 4.00 using the Qt library that will be available then
            # call browser.browser("Help","https://4js.com//mirror/documentation.php?s=genero&f=fjs-genero-3.20.XX-PlatformsDb.pdf")
            CALL ui.Interface.frontCall(
                "standard", "launchUrl", "https://4js.com//mirror/documentation.php?s=genero&f=fjs-genero-3.20.XX-PlatformsDb.pdf",
                [])

        ON ACTION video
            IF ui.Interface.getFrontEndName() = "GBC" OR ui.Interface.getUniversalClientName() = "GBC" THEN
                CALL browser.browser("Introduction", "https://www.youtube.com/embed/dM9rKLB7_2o")
            ELSE
                CALL browser.browser("Introduction", "https://www.youtube.com/watch?v=dM9rKLB7_2o")
            END IF

        ON ACTION about
            CALL lib_ui.show_message(about_text(), TRUE)
    END MENU
    IF int_flag THEN
        LET int_flag = 0
    END IF
END FUNCTION

PRIVATE FUNCTION delete_database()
    IF lib_ui.confirm_dialog("Are you sure you want to delete ALL job data?") THEN
        BEGIN WORK
        TRY
            DELETE FROM job_detail WHERE 1 = 1
            DELETE FROM job_note WHERE 1 = 1
            DELETE FROM job_photo WHERE 1 = 1
            DELETE FROM job_timesheet WHERE 1 = 1
            DELETE FROM job_header WHERE 1 = 1
        CATCH
            ROLLBACK WORK
            RETURN FALSE, "Unable to delete job data"
        END TRY
        COMMIT WORK
        RETURN TRUE, "ALL job data deleted"
    ELSE
        RETURN FALSE, "Deletion of all job data cancelled"
    END IF
END FUNCTION

PRIVATE FUNCTION about_text()
    DEFINE sb base.StringBuffer

    LET sb = base.StringBuffer.create()
    CALL sb.append("This application was produced by Four Js Development Tools (www.4js.com)")
    CALL sb.append("\n\n")
    CALL sb.append("It is intended to illustrate a working application using Genero Mobile.")
    RETURN sb.toString()
END FUNCTION
