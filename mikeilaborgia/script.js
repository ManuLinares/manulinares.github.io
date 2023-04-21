function fadeInTopImage() {
  document.body.classList.add('fadeInClass');
}

function preloadImage(url, callback)
{
    var img=new Image();
    img.src=url;
    img.onload = callback;
}

//Wait till first image loaded and FadeIn animation
document.querySelector("#topimagePreload").addEventListener("load", fadeInTopImage);
//Force preload
preloadImage('img/0.jpg', fadeInTopImage);
//if everything else fails, fadeIn after X time anyway
setTimeout(function() {
  document.body.classList.add('fadeInClass');
}, 5000);

//Copy "down" arrow to all other slides
$( ".arrow" ).clone().appendTo( ".slide" ).each(function( index ) {
  //console.log( index + ": " + $( this ).children('a').attr('href') );
  count = $(".slide").length;
  if ( index <= (count-2) ) { 
    $( this ).children('a').attr('href', '#slide' + (index+1));
  } else {
    $( this ).children('a').attr('href', '#slide0')
        .children('svg').css({'transform':'rotate(180deg)'});
  };
});


document.addEventListener("DOMContentLoaded", function() {
  var lazyloadImages;    

  if ("IntersectionObserver" in window) {
    lazyloadImages = document.querySelectorAll(".lazy");
    var imageObserver = new IntersectionObserver(function(entries, observer) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          var image = entry.target;
          image.classList.remove("lazy");
          imageObserver.unobserve(image);
        }
      });
    });

    lazyloadImages.forEach(function(image) {
      imageObserver.observe(image);
    });
  } else {  
    var lazyloadThrottleTimeout;
    lazyloadImages = document.querySelectorAll(".lazy");
    
    function lazyload () {
      if(lazyloadThrottleTimeout) {
        clearTimeout(lazyloadThrottleTimeout);
      }    

      lazyloadThrottleTimeout = setTimeout(function() {
        var scrollTop = window.pageYOffset;
        lazyloadImages.forEach(function(img) {
            if(img.offsetTop < (window.innerHeight + scrollTop)) {
              img.src = img.dataset.src;
              img.classList.remove('lazy');
            }
        });
        if(lazyloadImages.length == 0) { 
          document.removeEventListener("scroll", lazyload);
          window.removeEventListener("resize", lazyload);
          window.removeEventListener("orientationChange", lazyload);
        }
      }, 20);
    }

    document.addEventListener("scroll", lazyload);
    window.addEventListener("resize", lazyload);
    window.addEventListener("orientationChange", lazyload);
  }
})