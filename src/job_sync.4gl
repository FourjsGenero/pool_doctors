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

import com
import util

import fgl lib_error

import fgl ws_customer
import fgl ws_job
import fgl ws_product

import fgl lib_job_header
import fgl lib_customer
import fgl lib_settings

schema pool_doctors

define m_count record
    customer integer,
    product integer,
    job_get integer,
    job_put integer,
    job_deleted integer
end record

constant rep string =  "01" -- TODO replace with unique identifier for device?



private function exception()
    whenever any error call lib_error.serious_error
end function



function execute()
define l_ok boolean
define l_err_text string

    if not test_connected() then
        return false, "Must be connected to internet"
    end if

    initialize m_count.* to null
    let l_ok = true
    if l_ok then
        call refresh_product() returning l_ok, l_err_text
    end if
    if l_ok then 
        call refresh_customer() returning l_ok, l_err_text
    end if
    if l_ok then
        call refresh_job_header() returning l_ok, l_err_text
    end if
    if l_ok then
        call send_jobs() returning l_ok, l_err_text
    end if
    if l_ok then
        call delete_old_jobs() returning l_ok, l_err_text
    end if
    if l_ok then
        let l_err_text = sfmt("%1 new jobs loaded\n%2 product records refreshed\n %3 customer records refresh\n%4 completed jobs uploaded\n%5 old jobs deleted", m_count.job_get, m_count.product, m_count.customer, m_count.job_put, m_count.job_deleted)
    end if
    return l_ok, l_err_text
end function



function create_random_job()
define l_ok boolean
define l_err_text string

define l_url string

define s string

define wsstatus integer

    if not test_connected() then
        return false, "Must be connected to internet"
    end if

    -- TODO Override URL with value in setting
    call ws_job.createRandomJob(rep) returning wsstatus, s 

    if wsstatus = ws_job.C_SUCCESS then
        let l_ok = true
        let l_err_text = sfmt("New job created %1", s)
    else
        let l_ok = false
        let l_err_text = "Error creating job\n", ws_job.ws_error.message
    end if
    return l_ok, l_err_text
end function



private function refresh_customer()
define l_customer_list  ws_customer.listResponseBodyType
define l_customer_rec   ws_customer.getResponseBodyType
define i integer
define wsstatus integer

    -- TODO Override URL with value in setting
    call ws_customer.list() RETURNING wsstatus, l_customer_list.*
    if wsstatus = ws_customer.C_SUCCESS then
        begin work
        delete from customer where 1=1
        for i = 1 to l_customer_list.rows.getLength()
            let l_customer_rec.* = l_customer_list.rows[i].*
            
            insert into customer values l_customer_rec.*
        end for
        commit work
        let m_count.customer = l_customer_list.rows.getLength()
        return true, ""
    else
        return false, ws_customer.ws_error.message
    end if
end function



private function refresh_product()
define l_product_list  ws_product.listResponseBodyType
define l_product_rec   ws_product.getResponseBodyType
define i integer
define wsstatus integer

   -- TODO Override URL with value in setting
    call ws_product.list() RETURNING wsstatus, l_product_list.*
    if wsstatus = ws_product.C_SUCCESS then
        begin work
        delete from product where 1=1
        for i = 1 to l_product_list.rows.getLength()
            let l_product_rec.* = l_product_list.rows[i].*
            
            insert into product values l_product_rec.*
        end for
        commit work
        let m_count.product = l_product_list.rows.getLength()
        return true, ""
    else
        return false, ws_product.ws_error.message
    end if
end function



private function refresh_job_header()

define wsstatus integer


define i integer
define l_job_header_rec record like job_header.*

define l_job_resp ws_job.getJobsForRepResponseBodyType


    let m_count.job_get = 0

     -- TODO Override URL with value in setting
    call ws_job.getJobsForRep(rep) RETURNING wsstatus, l_job_resp.*
    if wsstatus = ws_job.C_SUCCESS then
        begin work
        try
        for i = 1 to l_job_resp.rows.getLength()
            initialize l_job_header_rec.* to null
            -- only load job if it isn't in our system, and doesn't belong to rep
            let l_job_header_rec.jh_code =  l_job_resp.rows[i].jh_code
       
            if  lib_job_header.exists(l_job_header_rec.jh_code) then
                -- job is in database already
                continue for
            end if

            if  l_job_resp.rows[i].jh_status = "X" then
                -- job is complete
                continue for
            end if
            let l_job_header_rec.jh_customer =l_job_resp.rows[i].jh_customer
            let l_job_header_rec.jh_address1 = l_job_resp.rows[i].jh_address1
            let l_job_header_rec.jh_address2 = l_job_resp.rows[i].jh_address2
            let l_job_header_rec.jh_address3 = l_job_resp.rows[i].jh_address3
            let l_job_header_rec.jh_address4 = l_job_resp.rows[i].jh_address4
            let l_job_header_rec.jh_contact = l_job_resp.rows[i].jh_contact
            let l_job_header_rec.jh_date_created = l_job_resp.rows[i].jh_date_created
            let l_job_header_rec.jh_phone = l_job_resp.rows[i].jh_phone
            let l_job_header_rec.jh_status = l_job_resp.rows[i].jh_status
            let l_job_header_rec.jh_task_notes = l_job_resp.rows[i].jh_task_notes

            let m_count.job_get = m_count.job_get + 1
            insert into job_header values (l_job_header_rec.*)
            
        end for
        catch
            rollback work
            return false, ""
        end try
        commit work
        
    
    else
        return false, ws_job.ws_error.message
    end if
    return true, ""
    
end function



private function send_jobs()
define l_ok boolean
define l_err_text string

define l_url string

define job_data ws_job.uploadJobRequestBodyType
define wsstatus integer

define l_sql string

define l_job_header record like job_header.*
define l_job_detail record like job_detail.*
define l_job_note record like job_note.*
define l_job_photo record like job_photo.*
define l_job_timesheet record like job_timesheet.*   
define i integer


    let l_url = sfmt("%1/ws/r/%2/service/putJob", lib_settings.js_url, lib_settings.js_group)

    let l_sql = "select * from job_header where jh_status = 'X'"
    prepare job_header_text from l_sql
    declare job_header_curs cursor for job_header_text

    let l_sql = "select * from job_detail where jd_code= ? order by jd_line"
    prepare job_detail_text from l_sql
    declare job_detail_curs cursor for job_detail_text

    let l_sql = "select * from job_note where jn_code= ? order by jn_idx"
    prepare job_note_text from l_sql
    declare job_note_curs cursor for job_note_text

    let l_sql = "select * from job_photo where jp_code= ? order by jp_idx"
    prepare job_photo_text from l_sql
    declare job_photo_curs cursor for job_photo_text

    let l_sql = "select * from job_timesheet where jt_code= ? order by jt_idx"
    prepare job_timesheet_text from l_sql
    declare job_timesheet_curs cursor for job_timesheet_text

    let m_count.job_put = 0
    let l_ok = true

    foreach job_header_curs into l_job_header.*
        initialize job_data.* to null
        -- let job_data.job_header.cm_rep = rep  TODO Why is rep missing?
        let job_data.job_header.jh_address1 = l_job_header.jh_address1
        let job_data.job_header.jh_address2 = l_job_header.jh_address2
        let job_data.job_header.jh_address3 = l_job_header.jh_address3
        let job_data.job_header.jh_address4 = l_job_header.jh_address4
        let job_data.job_header.jh_code = l_job_header.jh_code
        let job_data.job_header.jh_contact = l_job_header.jh_contact
        let job_data.job_header.jh_customer = l_job_header.jh_customer
        let job_data.job_header.jh_date_created = l_job_header.jh_date_created
        let job_data.job_header.jh_date_signed = l_job_header.jh_date_signed
        let job_data.job_header.jh_name_signed = l_job_header.jh_name_signed
        let job_data.job_header.jh_phone = l_job_header.jh_phone
        let job_data.job_header.jh_signature = l_job_header.jh_signature
        let job_data.job_header.jh_status = l_job_header.jh_status
        let job_data.job_header.jh_task_notes = l_job_header.jh_task_notes

        let i = 0
        foreach job_detail_curs using l_job_header.jh_code into l_job_detail.*
            let i = i + 1
            let job_data.job_detail[i].jd_code = l_job_detail.jd_code
            let job_data.job_detail[i].jd_line = l_job_detail.jd_line
            let job_data.job_detail[i].jd_product = l_job_detail.jd_product
            let job_data.job_detail[i].jd_qty = l_job_detail.jd_qty
           let job_data.job_detail[i].jd_status = l_job_detail.jd_status
        end foreach

        let i = 0
        foreach job_note_curs using l_job_header.jh_code into l_job_note.*
            let i = i + 1
            let job_data.job_note[i].jn_code = l_job_note.jn_code
            let job_data.job_note[i].jn_idx = l_job_note.jn_idx
            let job_data.job_note[i].jn_note = l_job_note.jn_note
            let job_data.job_note[i].jn_when = l_job_note.jn_when
        end foreach

        let i = 0
        foreach job_photo_curs using l_job_header.jh_code into l_job_photo.*
            let i = i + 1
            let job_data.job_photo[i].jp_code = l_job_photo.jp_code
            let job_data.job_photo[i].jp_idx = l_job_photo.jp_idx
            let job_data.job_photo[i].jp_lat = l_job_photo.jp_lat            
            let job_data.job_photo[i].jp_lon = l_job_photo.jp_lon
            let job_data.job_photo[i].jp_photo = l_job_photo.jp_photo
            let job_data.job_photo[i].jp_when = l_job_photo.jp_when
           
        end foreach

        let i = 0
        
        foreach job_timesheet_curs using l_job_header.jh_code into l_job_timesheet.*
            let i =i + 1
            let job_data.job_timesheet[i].jt_code = l_job_timesheet.jt_code
            let job_data.job_timesheet[i].jt_idx = l_job_timesheet.jt_idx
            let job_data.job_timesheet[i].jt_start = l_job_timesheet.jt_start
            let job_data.job_timesheet[i].jt_finish = l_job_timesheet.jt_finish
            let job_data.job_timesheet[i].jt_charge_code_id = l_job_timesheet.jt_charge_code_id
            let job_data.job_timesheet[i].jt_text = l_job_timesheet.jt_text
        end foreach

        call ws_job.uploadJob(job_data.*) returning wsstatus
   
        if wsstatus = ws_job.C_SUCCESS then
            let l_ok = true
            let m_count.job_put = m_count.job_put + 1
        else
            let l_ok = false
            let l_err_text = "Error syncing Job:", l_job_header.jh_code, " ", ws_job.ws_error.message
            exit foreach
        end if

        -- Upload photos
        foreach job_photo_curs using l_job_header.jh_code into l_job_photo.*
            let i = i + 1

            CALL ws_job.uploadJobPhoto(
                    l_job_photo.jp_code, l_job_photo.jp_idx, l_job_photo.jp_photo)
                RETURNING wsstatus
            IF wsstatus = ws_job.C_SUCCESS THEN
                --carry on
            ELSE
                -- TODO should we stop?
            END IF
        END FOReach


        
    end foreach
    if not l_ok then
        return false, l_err_text
    end if
    return true, ""
end function



private function delete_old_jobs()
define l_sql string
define l_jh_code like job_header.jh_code

define l_cutoff_date like job_header.jh_date_signed
define l_days_to_keep_str string
define l_days_to_keep interval day to day

    -- delete jobs that are more than 7 days old and have been synced
    -- generate interval variable of 7 days and delete form current date
    let l_days_to_keep_str = "7"
    let l_days_to_keep  = l_days_to_keep_str

    let l_cutoff_date = current year to minute
    let l_cutoff_date = l_cutoff_date - l_days_to_keep

    let l_sql = "select jh_code from job_header where jh_status = 'X' and jh_date_signed <= ? "
    let m_count.job_deleted = 0
  
    begin work
    try
        prepare delete_old_jobs_text from l_sql
        declare delete_old_jobs_curs cursor for delete_old_jobs_text
        foreach delete_old_jobs_curs using l_cutoff_date into l_jh_code
            delete from job_detail where jd_code = l_jh_code
            delete from job_note where jn_code = l_jh_code
            delete from job_photo where jp_code = l_jh_code
            delete from job_timesheet where jt_code = l_jh_code
            delete from job_header where jh_code = l_jh_code
            let m_count.job_deleted = m_count.job_deleted + 1
        end foreach
    catch
        rollback work
        let m_count.job_deleted = 0
        return false, sqlca.sqlerrm
    end try
    commit work
    return true, ""
end function



private function test_connected()
define l_ipaddress string

    if not base.Application.isMobile() then
        return true
    end if
    call ui.interface.frontCall("standard","feinfo","ip", l_ipaddress)
    
    -- TODO: This line is required due to bug that prevented the refresh icon appearing
    -- Having this line makes the refresh icon appear
    CALL ui.Interface.refresh()  
    
    if l_ipaddress.getLength() > 0 then
        return true
    end if
    return false
end function
