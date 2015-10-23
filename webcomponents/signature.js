//
//       (c) Copyright 2014, Blue J Software - www.bluejs.com
//
//       MIT License (http://www.opensource.org/licenses/mit-license.php)
//
//       Permission is hereby granted, free of charge, to any person
//       obtaining a copy of this software and associated documentation
//       files (the "Software"), to deal in the Software without restriction,
//       including without limitation the rights to use, copy, modify, merge,
//       publish, distribute, sublicense, and/or sell copies of the Software,
//       and to permit persons to whom the Software is furnished to do so,
//       subject to the following conditions:
//
//       The above copyright notice and this permission notice shall be
//       included in all copies or substantial portions of the Software.
//
//       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//       EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//       OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//       NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
//       BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//       ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//       CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//       THE SOFTWARE.

// The signature web component was derived from this stack overflow question ...
// http://stackoverflow.com/questions/7522198/form-submit-a-signature-captured-using-svg

// This function is called by the Genero Client Container
// so the web component can initialize itself and initialize
// the gICAPI handlers
onICHostReady = function(version) {
   if ( version != 1.0 ) {
      alert('Invalid API version');
      return;
   }

   // Initialize the focus handler called by the Genero Client
   // Container when the DVM set/remove the focus to/from the
   // component
   gICAPI.onFocus = function(polarity) {
      /* looks bad on IOS, we need to add a possibility to know the client
      if ( polarity ) {
         document.body.style.border = '1px solid blue';
      } else {
         document.body.style.border = '1px solid grey';
      }
      */
   }
            

   // Initialize the data handler ... 
   // This component does not care about the data set by the DVM ...
   // so nothing to do.
   // Perhaps one day use it to view a signature
   // gICAPI.onData = function(dt) {
   //}

   gICAPI.onData = function(data) {
     signaturePath = data;
     p.setAttribute('d', data);
   }

   

   gICAPI.onProperty = function(property) {
      
      myProps = eval('(' + property + ')');
      //alert("props:"+JSON.stringify(myProps));
      
      if (myProps.action == 'clear') {
         clearSignature();
      }
   }

   // When the user click on the document we ask the DVM to
   // get the focus
   askFocus = function() {
      //Seems to cause GDC to crash
      gICAPI.SetFocus();
   }
}

function checkSvg() {
   r = document.getElementById('r');
   p = document.getElementById('p');
   signaturePath = '',
   isDown = false;
   r.addEventListener('mousedown', down, false);
   r.addEventListener('mousemove', move, false);
   r.addEventListener('mouseup', up, false);
   r.addEventListener('touchstart', down, false);
   r.addEventListener('touchmove', move, false);
   r.addEventListener('touchend', up, false);
   r.addEventListener('mouseout', up, false);
}

function isTouchEvent(e) {
   return e.type.match(/^touch/);
}

function getCoords(e) {
  if (isTouchEvent(e)) {
     return e.targetTouches[0].clientX + ',' + e.targetTouches[0].clientY;
  }
  return e.clientX + ',' + e.clientY;
}

function down(e) {
  // Make sure has the 4gl focus if user clicks inside
  // Seems to cause the GDC to crash
  gICAPI.SetFocus();
      
  signaturePath += 'M' + getCoords(e) + ' ';
  p.setAttribute('d', signaturePath);
  isDown = true;
      
  if (isTouchEvent(e)) e.preventDefault();
  gICAPI.SetData(signaturePath);
}

function move(e) {
  if (isDown) {
    signaturePath += 'L' + getCoords(e) + ' ';
    p.setAttribute('d', signaturePath);
  }

  if (isTouchEvent(e)) e.preventDefault();
  gICAPI.SetData(signaturePath);
}

function up(e) {
  isDown = false; 

  if (isTouchEvent(e)) e.preventDefault();

  // update the data when end of movement 
  gICAPI.SetData(signaturePath);
}

function clearSignature() {
   signaturePath = '';
   p.setAttribute('d', '');
   gICAPI.SetData(signaturePath);
}
