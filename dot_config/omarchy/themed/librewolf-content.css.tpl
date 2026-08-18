/* Omarchy theme for LibreWolf's own pages, generated on every theme change.
 *
 * Only the pages the browser draws itself. Nothing here reaches a website. */

@-moz-document url-prefix("about:newtab"), url-prefix("about:home"), url-prefix("about:privatebrowsing"), url-prefix("about:blank") {
  :root {
    --newtab-background-color: {{ background }} !important;
    --newtab-background-color-secondary: {{ lighter_background }} !important;
    --newtab-text-primary-color: {{ foreground }} !important;
    --newtab-primary-action-background: {{ accent }} !important;
    background-color: {{ background }} !important;
    color-scheme: {{ mode }} !important;
  }

  body {
    background-color: {{ background }} !important;
  }
}
