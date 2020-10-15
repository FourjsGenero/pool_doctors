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

import fgl lib_error
import fgl lib_ui
import fgl lib_settings
import fgl browser

import fgl job_sync
import fgl job_header_list
import fgl job_settings
import os



private function exception()
    whenever any error call lib_error.serious_error
end function



function execute()
    open window home with form "home"    
    call home()
    close window home
end function




private function home()
define l_ok boolean
define l_err_text string

    menu ""
        before menu
            call dialog.setActionActive("settings", true)
        
        on action home
            call job_header_list.list()

        on action settings
            menu "" attributes(style="popup")
                on action edit_settings attributes(text="Edit Settings")
                    call job_settings.edit() returning l_ok, l_err_text
                    if l_ok then
                        call lib_ui.show_message(l_err_text,true)
                    else
                        call lib_ui.show_error(l_err_text, true)
                    end if
                    
                on action random attributes(text="Create Random Job")
                    -- simulate the creation of a new job
                    call job_sync.create_random_job() returning l_ok, l_err_text
                    if l_ok then
                        call lib_ui.show_message(l_err_text,true)
                    else
                        call lib_ui.show_error(l_err_text, true)
                    end if
                    
                on action delete_all attributes(text= "Delete ALL Job Data")
                    call delete_database() returning l_ok, l_err_text
                    if l_ok then
                        call lib_ui.show_message(l_err_text,true)
                    else
                        call lib_ui.show_error(l_err_text, true)
                    end if
                    
                on action force_error attributes(text= "Force Error")  -- used to test error handling
                    -- need to stop program terminating on error or else fails to get into App Store
                    call lib_error.test_mode(true)   -- set so does not stop program
                    display 1/0                      -- this will make program error
                    call lib_error.test_mode(false)

                on action view_errorlog attributes(text="View Error Log")
                    call lib_error.view_errorlog()
                    
                on action clear_error attributes(text="Clear Error Log")
                    call clear_errorlog() returning l_ok, l_err_text
                    if l_ok then
                        call lib_ui.show_message(l_err_text,true)
                    else
                        call lib_ui.show_error(l_err_text, true)
                    end if
               
            end menu
                
        on action refresh 
            call job_sync.execute() returning l_ok, l_err_text
            if l_ok then
                call lib_ui.show_message("Sync Result\n"||l_err_text,true)
            else
                call lib_ui.show_error("Sync Result\n"||l_err_text,true)
            end if

        on action help 
            -- Use Supported Systems Document as example of similar sized PDF
            -- Consider using browser.browser when NULL Web Component can handle PDF
            -- I think that will be GDD 4.00 using the Qt library that will be available then 
            # call browser.browser("Help","https://4js.com//mirror/documentation.php?s=genero&f=fjs-genero-3.20.XX-PlatformsDb.pdf")
            call ui.Interface.frontCall("standard","launchUrl","https://4js.com//mirror/documentation.php?s=genero&f=fjs-genero-3.20.XX-PlatformsDb.pdf",[])
          
        on action video
            if ui.Interface.getFrontEndName() = "GBC"
            OR ui.Interface.getUniversalClientName() = "GBC" THEN
                call browser.browser("Introduction","https://www.youtube.com/embed/dM9rKLB7_2o")
            else
                call browser.browser("Introduction","https://www.youtube.com/watch?v=dM9rKLB7_2o")
            end if

        on action about
            call lib_ui.show_message(about_text(), true)            
    end menu
    if int_flag then
        let int_flag = 0
    end if
end function



private function delete_database()
    if lib_ui.confirm_dialog("Are you sure you want to delete ALL job data?") then
        begin work
        try 
            delete from job_detail where 1=1
            delete from job_note where 1=1
            delete from job_photo where 1=1
            delete from job_timesheet where 1=1
            delete from job_header where 1=1
        catch
            rollback work
            return false, "Unable to delete job data"
        end try
        commit work
        return true, "ALL job data deleted"
    else
        return false, "Deletion of all job data cancelled"
    end if
end function



private function about_text()
define sb base.StringBuffer

    let sb = base.StringBuffer.create()
    call sb.append("This application was produced by Four Js Development Tools (www.4js.com)")
    call sb.append("\n\n")
    call sb.append("It is intended to illustrate a working application using Genero Mobile.")
    return sb.toString()
end function
