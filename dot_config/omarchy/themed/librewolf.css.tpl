/* Omarchy theme for LibreWolf, generated on every theme change.
 *
 * These are the variables a Firefox theme extension sets, written straight
 * into the chrome instead. Whatever theme the browser itself has active keeps
 * its structure; only the colours below are taken from Omarchy. */

:root {
  --toolbar-color-scheme: {{ mode }} !important;

  /* Window frame and the tab strip on it */
  --lwt-accent-color: {{ darker_background }} !important;
  --lwt-accent-color-inactive: {{ darker_background }} !important;
  --lwt-text-color: {{ light_foreground }} !important;
  --lwt-background-tab-separator-color: transparent !important;

  /* The selected tab, and the line drawn along its top */
  --tab-background-color-selected: {{ background }} !important;
  --tab-selected-textcolor: {{ bright_foreground }} !important;
  --lwt-tab-line-color: {{ accent }} !important;
  --tab-loading-fill: {{ accent }} !important;

  /* Navigation and bookmarks toolbars */
  --toolbar-background-color: {{ background }} !important;
  --toolbar-text-color: {{ foreground }} !important;
  --toolbarbutton-icon-fill: {{ light_foreground }} !important;
  --toolbarbutton-icon-fill-attention: {{ accent }} !important;
  --toolbarbutton-background-color-hover: {{ lighter_background }} !important;
  --toolbarbutton-background-color-active: {{ selection }} !important;

  /* Address bar and search bar */
  --toolbar-field-background-color: {{ dark_background }} !important;
  --toolbar-field-text-color: {{ foreground }} !important;
  --toolbar-field-border-color: {{ lighter_background }} !important;
  --toolbar-field-background-color-focus: {{ dark_background }} !important;
  --toolbar-field-text-color-focus: {{ bright_foreground }} !important;
  --toolbar-field-border-color-focus: {{ accent }} !important;
  --lwt-toolbar-field-highlight: {{ selection }} !important;
  --lwt-toolbar-field-highlight-text: {{ bright_foreground }} !important;

  /* Address bar results */
  --urlbarview-background-color-selected: {{ selection }} !important;
  --urlbarview-text-color-selected: {{ bright_foreground }} !important;

  /* Menus and doorhangers that hang off a toolbar button */
  --panel-background-color: {{ background }} !important;
  --panel-text-color: {{ foreground }} !important;
  --panel-border-color: {{ lighter_background }} !important;

  /* Separators */
  --toolbarseparator-color: {{ lighter_background }} !important;
  --tabs-navbar-separator-color: transparent !important;
  --chrome-content-separator-color: {{ lighter_background }} !important;

  /* Sidebar */
  --sidebar-background-color: {{ dark_background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --sidebar-border-color: {{ lighter_background }} !important;

  /* The colour behind a tab before its page paints, and the one popups
   * anchored over the new tab page match themselves to */
  --tabpanel-background-color: {{ background }} !important;
  --newtab-background-color: {{ background }} !important;
  --newtab-background-color-secondary: {{ lighter_background }} !important;
  --newtab-text-primary-color: {{ foreground }} !important;
}

/* Findbar, notification bars and the like sit outside the toolbox */
#browser {
  --toolbar-bgcolor: {{ background }} !important;
}
