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

SCHEMA "pool_doctors"

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

-- For a given product, return the description
FUNCTION lookup_pr_desc(l_pr_code)
    DEFINE l_pr_code LIKE product.pr_code
    DEFINE l_pr_desc LIKE product.pr_desc

    SELECT product.pr_desc INTO l_pr_desc FROM product WHERE product.pr_code = l_pr_code

    RETURN l_pr_desc
END FUNCTION

-- For a given barcode, return the product code
FUNCTION find_from_barcode(l_barcode)
    DEFINE l_barcode LIKE product.pr_barcode

    DEFINE l_pr_code LIKE product.pr_code

    -- assumes barcode is unique in product table
    IF l_barcode IS NOT NULL THEN
        SELECT pr_code INTO l_pr_code FROM product WHERE pr_barcode = l_barcode
    END IF

    RETURN l_pr_code
END FUNCTION

-- Determine if a given product exists
FUNCTION exists(l_pr_code)
    DEFINE l_pr_code LIKE product.pr_code

    SELECT 'x' FROM product WHERE product.pr_code = l_pr_code

    IF status == NOTFOUND THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
