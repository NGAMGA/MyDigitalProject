(function () {
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('komi_service_worker.js');
    });
  }

  var installPrompt = null;
  var banner = document.getElementById('install-komi-banner');
  var button = document.getElementById('install-komi');
  var dismissButton = document.getElementById('dismiss-install-komi');
  var help = document.getElementById('install-help');
  var dismissalKey = 'komi-install-dismissed';
  var isStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true;
  var isIos = /iphone|ipad|ipod/i.test(window.navigator.userAgent);
  var isDismissed = window.localStorage.getItem(dismissalKey) === 'true';

  if (!banner || !button || isStandalone || isDismissed) return;

  function showButton() {
    banner.style.display = 'inline-flex';
  }

  function hideInstaller() {
    banner.style.display = 'none';
    if (help) help.style.display = 'none';
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
      hideInstaller();
      return;
    }

    if (isIos && help) {
      help.style.display = 'block';
      window.setTimeout(function () {
        help.style.display = 'none';
      }, 7000);
    }
  });

  if (dismissButton) {
    dismissButton.addEventListener('click', function () {
      window.localStorage.setItem(dismissalKey, 'true');
      installPrompt = null;
      hideInstaller();
    });
  }

  window.addEventListener('appinstalled', function () {
    installPrompt = null;
    hideInstaller();
  });
})();
