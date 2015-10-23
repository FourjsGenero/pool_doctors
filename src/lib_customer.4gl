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



-- For a given customer, return the name
function lookup_cm_name(l_cm_code)
define l_cm_code like customer.cm_code
define l_cm_name like customer.cm_name
    
    select customer.cm_name
    into l_cm_name
    from customer
    where customer.cm_code = l_cm_code

    return l_cm_name
end function



-- For a given customer, return the rep code
function lookup_cm_rep(l_cm_code)
define l_cm_code like customer.cm_code
define l_cm_rep like customer.cm_rep
    
    select customer.cm_rep
    into l_cm_rep
    from customer
    where customer.cm_code = l_cm_code

    return l_cm_rep
end function