export function wireDock(root, onOpenApp) {
  root.querySelectorAll('.dock button').forEach((button) => {
    button.addEventListener('click', () => onOpenApp(button.dataset.app));
  });
}
