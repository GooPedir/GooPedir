export function SetCookie(name, value, duration) {

  //localStorage.setItem(name,value);
  //localStorage.getItem("mykey");


    var cookie = name + "=" + escape(value) +
    ((duration) ? "; duration=" + duration.toGMTString() : "");
  
    document.cookie = cookie;
  }