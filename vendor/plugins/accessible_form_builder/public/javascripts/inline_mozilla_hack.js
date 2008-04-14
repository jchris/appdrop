// The following is based on code from http://alistapart.com/articles/prettyaccessibleforms ;

// It's a hack because mozilla does not support inline-block
if( document.addEventListener ) document.addEventListener( 'DOMContentLoaded', cmxform, false);
$j=jQuery.noConflict();

function cmxform(){
  // Hide forms
  $j( 'form.cmxform' ).hide().end();

  // Processing
  $j( 'form.cmxform' ).find( 'li/label' ).not( '.nocmx' ).each( function( i ){
    var labelContent = this.innerHTML;
    var labelWidth = document.defaultView.getComputedStyle( this, '' ).getPropertyValue( 'width' );
    var labelSpan = document.createElement( 'span' );
        labelSpan.style.display = 'block';
        labelSpan.style.width = labelWidth;
        labelSpan.innerHTML = labelContent;
    this.style.display = '-moz-inline-box';
    this.innerHTML = null;
    this.appendChild( labelSpan );
  } ).end();

  // Show forms
  $j( 'form.cmxform' ).show().end();
}
