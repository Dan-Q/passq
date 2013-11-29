var PassQ = PassQ || {
  init: function(username, password){
    this.account_key = CryptoJS.SHA3(username + ':' + password, { outputLength: 512 }).toString();
    this.crypto_key = CryptoJS.SHA3(password, { outputLength: 512 }).toString();
    return(this);
  },

  decrypt_password_safe: function(){
    this.decrypted_password_safe = $.parseJSON(CryptoJS.AES.decrypt(this.encrypted_password_safe, this.crypto_key).toString(CryptoJS.enc.Utf8));
    return(this);
  },

  encrypt_password_safe: function(){
    this.encrypted_password_safe = CryptoJS.AES.encrypt(JSON.stringify(this.decrypted_password_safe).toString(CryptoJS.enc.Base64), this.crypto_key).toString();
    return(this);
  },

  save: function(){
    this.encrypt_password_safe();
    $.post('/save', { account_key: this.account_key, encrypted_password_safe: this.encrypted_password_safe }, function(data, text_status, xhr){
      if(data == 'OK'){
        alert('Saved okay.')
      } else {
        alert(data);
      }
    }, 'text');
    return(this);
  }
};

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
      PassQ.init(username, password1).decrypted_password_safe = { passwords: [] };
      PassQ.encrypt_password_safe();
      $.post('/setup', { account_key: PassQ.account_key, empty_password_safe: PassQ.encrypted_password_safe }, function(data, text_status, xhr){
        if(data == 'OK') {
          alert('Registration successful. Log in.')
          window.location.href = '/'; // reload the page, now planning to see the login page
        } else {
          alert(data); // show the error message returned by the server
        }
      }, 'text');
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
      PassQ.init(username, password);
      $.post('/login', { account_key: PassQ.account_key }, function(data, text_status, xhr){
        if(data == ''){
          alert('Authentication failed.');
        }else{
          $('body').html('Decrypting passwords...');
          PassQ.encrypted_password_safe = data;
          PassQ.decrypt_password_safe();
          // clear page and load app content
          $('body').html('').load('/app');
        }
      }, 'text');
    });
  });
})();