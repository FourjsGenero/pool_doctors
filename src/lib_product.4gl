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

schema "pool_doctors"



private function exception()
    whenever any error call serious_error
end function



-- For a given product, return the description
function lookup_pr_desc(l_pr_code)
define l_pr_code like product.pr_code
define l_pr_desc like product.pr_desc
    
    select product.pr_desc
    into l_pr_desc
    from product
    where product.pr_code = l_pr_code

    return l_pr_desc
end function



-- For a given barcode, return the product code
function find_from_barcode(l_barcode)
define l_barcode like product.pr_barcode

define l_pr_code like product.pr_code

    -- assumes barcode is unique in product table
    if l_barcode is not null then
        select pr_code 
        into l_pr_code
        from product
        where pr_barcode = l_barcode
    end if

    return l_pr_code
end function



-- Determine if a given product exists
function exists(l_pr_code)
define l_pr_code like product.pr_code

    select 'x'
    from product
    where product.pr_code = l_pr_code

    if status==notfound then
        return false
    end if
    return true
end function