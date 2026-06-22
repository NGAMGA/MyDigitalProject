(function () {
  var installPrompt = null;
  var button = document.getElementById('install-komi');
  var help = document.getElementById('install-help');
  var isStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true;
  var isIos = /iphone|ipad|ipod/i.test(window.navigator.userAgent);

  if (!button || isStandalone) return;

  function showButton() {
    button.style.display = 'inline-flex';
  }

  window.addEventListener('beforeinstallprompt', function (event) {
    event.preventDefault();
    installPrompt = event;
    showButton();
  });

  if (isIos) showButton();

  button.addEventListener('click', async function () {
    if (installPrompt) {
      installPrompt.prompt();
      await installPrompt.userChoice;
      installPrompt = null;
      button.style.display = 'none';
      return;
    }

    if (isIos && help) {
      help.style.display = 'block';
      window.setTimeout(function () {
        help.style.display = 'none';
      }, 7000);
    }
  });

  window.addEventListener('appinstalled', function () {
    installPrompt = null;
    button.style.display = 'none';
    if (help) help.style.display = 'none';
  });
})();
