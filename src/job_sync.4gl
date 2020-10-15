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

IMPORT com
IMPORT util

IMPORT FGL lib_error

IMPORT FGL ws_customer
IMPORT FGL ws_job
IMPORT FGL ws_product

IMPORT FGL lib_job_header
IMPORT FGL lib_customer
IMPORT FGL lib_settings

SCHEMA pool_doctors

DEFINE m_count RECORD
    customer INTEGER,
    product INTEGER,
    job_get INTEGER,
    job_put INTEGER,
    job_deleted INTEGER
END RECORD

CONSTANT rep STRING = "01" -- TODO replace with unique identifier for device?

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

FUNCTION execute()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    IF NOT test_connected() THEN
        RETURN FALSE, "Must be connected to internet"
    END IF

    INITIALIZE m_count.* TO NULL
    LET l_ok = TRUE
    IF l_ok THEN
        CALL refresh_product() RETURNING l_ok, l_err_text
    END IF
    IF l_ok THEN
        CALL refresh_customer() RETURNING l_ok, l_err_text
    END IF
    IF l_ok THEN
        CALL refresh_job_header() RETURNING l_ok, l_err_text
    END IF
    IF l_ok THEN
        CALL send_jobs() RETURNING l_ok, l_err_text
    END IF
    IF l_ok THEN
        CALL delete_old_jobs() RETURNING l_ok, l_err_text
    END IF
    IF l_ok THEN
        LET l_err_text =
            SFMT("%1 new jobs loaded\n%2 product records refreshed\n %3 customer records refresh\n%4 completed jobs uploaded\n%5 old jobs deleted",
                m_count.job_get, m_count.product, m_count.customer, m_count.job_put, m_count.job_deleted)
    END IF
    RETURN l_ok, l_err_text
END FUNCTION

FUNCTION create_random_job()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    DEFINE l_url STRING

    DEFINE s STRING

    DEFINE wsstatus INTEGER

    IF NOT test_connected() THEN
        RETURN FALSE, "Must be connected to internet"
    END IF

    -- TODO Override URL with value in setting
    CALL ws_job.createRandomJob(rep) RETURNING wsstatus, s

    IF wsstatus = ws_job.C_SUCCESS THEN
        LET l_ok = TRUE
        LET l_err_text = SFMT("New job created %1", s)
    ELSE
        LET l_ok = FALSE
        LET l_err_text = "Error creating job\n", ws_job.ws_error.message
    END IF
    RETURN l_ok, l_err_text
END FUNCTION

PRIVATE FUNCTION refresh_customer()
    DEFINE l_customer_list ws_customer.listResponseBodyType
    DEFINE l_customer_rec ws_customer.getResponseBodyType
    DEFINE i INTEGER
    DEFINE wsstatus INTEGER

    -- TODO Override URL with value in setting
    CALL ws_customer.list() RETURNING wsstatus, l_customer_list.*
    IF wsstatus = ws_customer.C_SUCCESS THEN
        BEGIN WORK
        DELETE FROM customer WHERE 1 = 1
        FOR i = 1 TO l_customer_list.rows.getLength()
            LET l_customer_rec.* = l_customer_list.rows[i].*

            INSERT INTO customer VALUES l_customer_rec.*
        END FOR
        COMMIT WORK
        LET m_count.customer = l_customer_list.rows.getLength()
        RETURN TRUE, ""
    ELSE
        RETURN FALSE, ws_customer.ws_error.message
    END IF
END FUNCTION

PRIVATE FUNCTION refresh_product()
    DEFINE l_product_list ws_product.listResponseBodyType
    DEFINE l_product_rec ws_product.getResponseBodyType
    DEFINE i INTEGER
    DEFINE wsstatus INTEGER

    -- TODO Override URL with value in setting
    CALL ws_product.list() RETURNING wsstatus, l_product_list.*
    IF wsstatus = ws_product.C_SUCCESS THEN
        BEGIN WORK
        DELETE FROM product WHERE 1 = 1
        FOR i = 1 TO l_product_list.rows.getLength()
            LET l_product_rec.* = l_product_list.rows[i].*

            INSERT INTO product VALUES l_product_rec.*
        END FOR
        COMMIT WORK
        LET m_count.product = l_product_list.rows.getLength()
        RETURN TRUE, ""
    ELSE
        RETURN FALSE, ws_product.ws_error.message
    END IF
END FUNCTION

PRIVATE FUNCTION refresh_job_header()

    DEFINE wsstatus INTEGER

    DEFINE i INTEGER
    DEFINE l_job_header_rec RECORD LIKE job_header.*

    DEFINE l_job_resp ws_job.getJobsForRepResponseBodyType

    LET m_count.job_get = 0

    -- TODO Override URL with value in setting
    CALL ws_job.getJobsForRep(rep) RETURNING wsstatus, l_job_resp.*
    IF wsstatus = ws_job.C_SUCCESS THEN
        BEGIN WORK
        TRY
            FOR i = 1 TO l_job_resp.rows.getLength()
                INITIALIZE l_job_header_rec.* TO NULL
                -- only load job if it isn't in our system, and doesn't belong to rep
                LET l_job_header_rec.jh_code = l_job_resp.rows[i].jh_code

                IF lib_job_header.exists(l_job_header_rec.jh_code) THEN
                    -- job is in database already
                    CONTINUE FOR
                END IF

                IF l_job_resp.rows[i].jh_status = "X" THEN
                    -- job is complete
                    CONTINUE FOR
                END IF
                LET l_job_header_rec.jh_customer = l_job_resp.rows[i].jh_customer
                LET l_job_header_rec.jh_address1 = l_job_resp.rows[i].jh_address1
                LET l_job_header_rec.jh_address2 = l_job_resp.rows[i].jh_address2
                LET l_job_header_rec.jh_address3 = l_job_resp.rows[i].jh_address3
                LET l_job_header_rec.jh_address4 = l_job_resp.rows[i].jh_address4
                LET l_job_header_rec.jh_contact = l_job_resp.rows[i].jh_contact
                LET l_job_header_rec.jh_date_created = l_job_resp.rows[i].jh_date_created
                LET l_job_header_rec.jh_phone = l_job_resp.rows[i].jh_phone
                LET l_job_header_rec.jh_status = l_job_resp.rows[i].jh_status
                LET l_job_header_rec.jh_task_notes = l_job_resp.rows[i].jh_task_notes

                LET m_count.job_get = m_count.job_get + 1
                INSERT INTO job_header VALUES(l_job_header_rec.*)

            END FOR
        CATCH
            ROLLBACK WORK
            RETURN FALSE, ""
        END TRY
        COMMIT WORK

    ELSE
        RETURN FALSE, ws_job.ws_error.message
    END IF
    RETURN TRUE, ""

END FUNCTION

PRIVATE FUNCTION send_jobs()
    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    DEFINE l_url STRING

    DEFINE job_data ws_job.uploadJobRequestBodyType
    DEFINE wsstatus INTEGER

    DEFINE l_sql STRING

    DEFINE l_job_header RECORD LIKE job_header.*
    DEFINE l_job_detail RECORD LIKE job_detail.*
    DEFINE l_job_note RECORD LIKE job_note.*
    DEFINE l_job_photo RECORD LIKE job_photo.*
    DEFINE l_job_timesheet RECORD LIKE job_timesheet.*
    DEFINE i INTEGER

    LET l_url = SFMT("%1/ws/r/%2/service/putJob", lib_settings.js_url, lib_settings.js_group)

    LET l_sql = "select * from job_header where jh_status = 'X'"
    PREPARE job_header_text FROM l_sql
    DECLARE job_header_curs CURSOR FOR job_header_text

    LET l_sql = "select * from job_detail where jd_code= ? order by jd_line"
    PREPARE job_detail_text FROM l_sql
    DECLARE job_detail_curs CURSOR FOR job_detail_text

    LET l_sql = "select * from job_note where jn_code= ? order by jn_idx"
    PREPARE job_note_text FROM l_sql
    DECLARE job_note_curs CURSOR FOR job_note_text

    LET l_sql = "select * from job_photo where jp_code= ? order by jp_idx"
    PREPARE job_photo_text FROM l_sql
    DECLARE job_photo_curs CURSOR FOR job_photo_text

    LET l_sql = "select * from job_timesheet where jt_code= ? order by jt_idx"
    PREPARE job_timesheet_text FROM l_sql
    DECLARE job_timesheet_curs CURSOR FOR job_timesheet_text

    LET m_count.job_put = 0
    LET l_ok = TRUE

    FOREACH job_header_curs INTO l_job_header.*
        INITIALIZE job_data.* TO NULL
        -- let job_data.job_header.cm_rep = rep  TODO Why is rep missing?
        LET job_data.job_header.jh_address1 = l_job_header.jh_address1
        LET job_data.job_header.jh_address2 = l_job_header.jh_address2
        LET job_data.job_header.jh_address3 = l_job_header.jh_address3
        LET job_data.job_header.jh_address4 = l_job_header.jh_address4
        LET job_data.job_header.jh_code = l_job_header.jh_code
        LET job_data.job_header.jh_contact = l_job_header.jh_contact
        LET job_data.job_header.jh_customer = l_job_header.jh_customer
        LET job_data.job_header.jh_date_created = l_job_header.jh_date_created
        LET job_data.job_header.jh_date_signed = l_job_header.jh_date_signed
        LET job_data.job_header.jh_name_signed = l_job_header.jh_name_signed
        LET job_data.job_header.jh_phone = l_job_header.jh_phone
        LET job_data.job_header.jh_signature = l_job_header.jh_signature
        LET job_data.job_header.jh_status = l_job_header.jh_status
        LET job_data.job_header.jh_task_notes = l_job_header.jh_task_notes

        LET i = 0
        FOREACH job_detail_curs USING l_job_header.jh_code INTO l_job_detail.*
            LET i = i + 1
            LET job_data.job_detail[i].jd_code = l_job_detail.jd_code
            LET job_data.job_detail[i].jd_line = l_job_detail.jd_line
            LET job_data.job_detail[i].jd_product = l_job_detail.jd_product
            LET job_data.job_detail[i].jd_qty = l_job_detail.jd_qty
            LET job_data.job_detail[i].jd_status = l_job_detail.jd_status
        END FOREACH

        LET i = 0
        FOREACH job_note_curs USING l_job_header.jh_code INTO l_job_note.*
            LET i = i + 1
            LET job_data.job_note[i].jn_code = l_job_note.jn_code
            LET job_data.job_note[i].jn_idx = l_job_note.jn_idx
            LET job_data.job_note[i].jn_note = l_job_note.jn_note
            LET job_data.job_note[i].jn_when = l_job_note.jn_when
        END FOREACH

        LET i = 0
        FOREACH job_photo_curs USING l_job_header.jh_code INTO l_job_photo.*
            LET i = i + 1
            LET job_data.job_photo[i].jp_code = l_job_photo.jp_code
            LET job_data.job_photo[i].jp_idx = l_job_photo.jp_idx
            LET job_data.job_photo[i].jp_lat = l_job_photo.jp_lat
            LET job_data.job_photo[i].jp_lon = l_job_photo.jp_lon
            LET job_data.job_photo[i].jp_photo = l_job_photo.jp_photo
            LET job_data.job_photo[i].jp_when = l_job_photo.jp_when

        END FOREACH

        LET i = 0

        FOREACH job_timesheet_curs USING l_job_header.jh_code INTO l_job_timesheet.*
            LET i = i + 1
            LET job_data.job_timesheet[i].jt_code = l_job_timesheet.jt_code
            LET job_data.job_timesheet[i].jt_idx = l_job_timesheet.jt_idx
            LET job_data.job_timesheet[i].jt_start = l_job_timesheet.jt_start
            LET job_data.job_timesheet[i].jt_finish = l_job_timesheet.jt_finish
            LET job_data.job_timesheet[i].jt_charge_code_id = l_job_timesheet.jt_charge_code_id
            LET job_data.job_timesheet[i].jt_text = l_job_timesheet.jt_text
        END FOREACH

        CALL ws_job.uploadJob(job_data.*) RETURNING wsstatus

        IF wsstatus = ws_job.C_SUCCESS THEN
            LET l_ok = TRUE
            LET m_count.job_put = m_count.job_put + 1
        ELSE
            LET l_ok = FALSE
            LET l_err_text = "Error syncing Job:", l_job_header.jh_code, " ", ws_job.ws_error.message
            EXIT FOREACH
        END IF

        -- Upload photos
        FOREACH job_photo_curs USING l_job_header.jh_code INTO l_job_photo.*
            LET i = i + 1

            CALL ws_job.uploadJobPhoto(l_job_photo.jp_code, l_job_photo.jp_idx, l_job_photo.jp_photo) RETURNING wsstatus
            IF wsstatus = ws_job.C_SUCCESS THEN
                --carry on
            ELSE
                -- TODO should we stop?
            END IF
        END FOREACH

    END FOREACH
    IF NOT l_ok THEN
        RETURN FALSE, l_err_text
    END IF
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION delete_old_jobs()
    DEFINE l_sql STRING
    DEFINE l_jh_code LIKE job_header.jh_code

    DEFINE l_cutoff_date LIKE job_header.jh_date_signed
    DEFINE l_days_to_keep_str STRING
    DEFINE l_days_to_keep INTERVAL DAY TO DAY

    -- delete jobs that are more than 7 days old and have been synced
    -- generate interval variable of 7 days and delete form current date
    LET l_days_to_keep_str = "7"
    LET l_days_to_keep = l_days_to_keep_str

    LET l_cutoff_date = CURRENT YEAR TO MINUTE
    LET l_cutoff_date = l_cutoff_date - l_days_to_keep

    LET l_sql = "select jh_code from job_header where jh_status = 'X' and jh_date_signed <= ? "
    LET m_count.job_deleted = 0

    BEGIN WORK
    TRY
        PREPARE delete_old_jobs_text FROM l_sql
        DECLARE delete_old_jobs_curs CURSOR FOR delete_old_jobs_text
        FOREACH delete_old_jobs_curs USING l_cutoff_date INTO l_jh_code
            DELETE FROM job_detail WHERE jd_code = l_jh_code
            DELETE FROM job_note WHERE jn_code = l_jh_code
            DELETE FROM job_photo WHERE jp_code = l_jh_code
            DELETE FROM job_timesheet WHERE jt_code = l_jh_code
            DELETE FROM job_header WHERE jh_code = l_jh_code
            LET m_count.job_deleted = m_count.job_deleted + 1
        END FOREACH
    CATCH
        ROLLBACK WORK
        LET m_count.job_deleted = 0
        RETURN FALSE, sqlca.sqlerrm
    END TRY
    COMMIT WORK
    RETURN TRUE, ""
END FUNCTION

PRIVATE FUNCTION test_connected()
    DEFINE l_ipaddress STRING

    IF NOT base.Application.isMobile() THEN
        RETURN TRUE
    END IF
    CALL ui.interface.frontCall("standard", "feinfo", "ip", l_ipaddress)

    -- TODO: This line is required due to bug that prevented the refresh icon appearing
    -- Having this line makes the refresh icon appear
    CALL ui.Interface.refresh()

    IF l_ipaddress.getLength() > 0 THEN
        RETURN TRUE
    END IF
    RETURN FALSE
END FUNCTION
