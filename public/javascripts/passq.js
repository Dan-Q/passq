(function(){
  $(function(){
    // Setup form
    $('#setup-form').submit(function(e){
      e.preventDefault();
      var username = $('#setup-form #username').val();
      var password1 = $('#setup-form #password1').val();
      var password2 = $('#setup-form #password2').val();
      if(username == '' || password1 == '' || password2 == ''){
        alert('You must specify a username and password, and confirm the password.');
        return;
      } else if(password1 != password2) {
        alert('The two passwords did not match.');
        return;
      }
      var account_key = CryptoJS.SHA3(username + ':' + password1, { outputLength: 512 }).toString();
      var crypto_key = CryptoJS.SHA3(password1, { outputLength: 512 }).toString();
      var empty_password_safe = CryptoJS.AES.encrypt('[]'.toString(CryptoJS.enc.Base64), crypto_key).toString();
      $.post('/setup', { account_key: account_key, empty_password_safe: empty_password_safe }, null, 'script');
    });

    // Login form
    $('#login-form').submit(function(e){
      e.preventDefault();
      var username = $('#login-form #username').val();
      var password = $('#login-form #password').val();
      if(username == '' || password == ''){
        alert('You must specify a username and password.');
        return;
      }
      var account_key = CryptoJS.SHA3(username + ':' + password, { outputLength: 512 }).toString();
      var crypto_key = CryptoJS.SHA3(password, { outputLength: 512 }).toString();
      $.post('/login', { account_key: account_key }, function(data, text_status, xhr){
        if(data == ''){
          alert('auth failed');
        }else{
          var t = CryptoJS.AES.decrypt(data, crypto_key).toString(CryptoJS.enc.Utf8);
          alert(t);
        }
      }, 'text');
    });
  });
})();